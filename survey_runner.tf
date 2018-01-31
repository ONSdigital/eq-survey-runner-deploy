resource "aws_alb_target_group" "survey_runner" {
  name     = "${var.env}-sr"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${data.aws_alb.eq.vpc_id}"

  health_check = {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 5
    timeout             = 2
    path                = "/status"
  }

  tags {
    Environment = "${var.env}"
  }
}

resource "aws_alb_listener_rule" "survey_runner" {
  listener_arn = "${var.aws_alb_listener_arn}"
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.survey_runner.arn}"
  }

  condition {
    field  = "host-header"
    values = ["${aws_route53_record.survey_runner.name}"]
  }
}

resource "aws_route53_record" "survey_runner" {
  zone_id = "${data.aws_route53_zone.dns_zone.id}"
  name    = "${var.env}-surveys.${var.dns_zone_name}"
  type    = "CNAME"
  ttl     = "60"
  records = ["${data.aws_alb.eq.dns_name}"]
}

data "template_file" "survey_runner" {
  template = "${file("${path.module}/task-definitions/survey-runner.json")}"

  vars {
    EQ_RABBITMQ_HOST                     = "${var.rabbitmq_ip_prime}"
    EQ_RABBITMQ_HOST_SECONDARY           = "${var.rabbitmq_ip_failover}"
    EQ_RABBITMQ_QUEUE_NAME               = "${var.message_queue_name}"
    EQ_SERVER_SIDE_STORAGE_DATABASE_HOST = "${var.database_host}"
    EQ_SERVER_SIDE_STORAGE_DATABASE_PORT = "${var.database_port}"
    EQ_SERVER_SIDE_STORAGE_DATABASE_NAME = "${var.database_name}"
    EQ_LOG_LEVEL                         = "${var.eq_log_level}"
    EQ_UA_ID                             = "${var.google_analytics_code}"
    SECRETS_S3_BUCKET                    = "${var.s3_secrets_bucket}"
    EQ_SECRETS_FILE                      = "${var.secrets_file_name}"
    EQ_KEYS_FILE                         = "${var.keys_file_name}"
    AWS_DEFAULT_REGION                   = "${var.aws_default_region}"
    LOG_GROUP                            = "${aws_cloudwatch_log_group.survey_runner.name}"
    CONTAINER_REGISTRY                   = "${var.docker_registry}"
    CONTAINER_TAG                        = "${var.survey_runner_tag}"
    RESPONDENT_ACCOUNT_URL               = "${var.respondent_account_url}"
    EQ_SUBMITTED_RESPONSES_TABLE_NAME    = "${var.submitted_responses_table_name}"
    EQ_NEW_RELIC_ENABLED                 = "${var.new_relic_enabled}"
    NEW_RELIC_LICENSE_KEY                = "${var.new_relic_licence_key}"
    NEW_RELIC_APP_NAME                   = "${var.new_relic_app_name}"

  }
}

resource "aws_ecs_task_definition" "survey_runner" {
  family                = "${var.env}-survey-runner"
  container_definitions = "${data.template_file.survey_runner.rendered}"
  task_role_arn         = "${aws_iam_role.survey_runner_task.arn}"
}

resource "aws_ecs_service" "survey_runner" {
  depends_on = [
    "aws_alb_target_group.survey_runner",
    "aws_alb_listener_rule.survey_runner",
  ]

  name            = "${var.env}-survey-runner"
  cluster         = "${data.aws_ecs_cluster.ecs-cluster.id}"
  task_definition = "${aws_ecs_task_definition.survey_runner.family}"
  desired_count   = "${var.survey_runner_min_tasks}"
  iam_role        = "${aws_iam_role.survey_runner.arn}"

  placement_strategy {
    type  = "spread"
    field = "host"
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.survey_runner.arn}"
    container_name   = "survey-runner"
    container_port   = 5000
  }

  lifecycle {
    ignore_changes = ["placement_strategy"]
  }
}

resource "aws_iam_role" "survey_runner" {
  name = "${var.env}_iam_for_survey_runner"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ecs.amazonaws.com", "ecs-tasks.amazonaws.com"]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "survey_runner" {
  "statement" = {
    "effect" = "Allow"

    "actions" = [
      "elasticloadbalancing:*",
    ]

    "resources" = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "survey_runner" {
  name   = "${var.env}_iam_for_survey_runner"
  role   = "${aws_iam_role.survey_runner.id}"
  policy = "${data.aws_iam_policy_document.survey_runner.json}"
}

resource "aws_iam_role" "survey_runner_task" {
  name = "${var.env}_iam_for_survey_runner_task"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ecs-tasks.amazonaws.com"]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "survey_runner_task" {
  "statement" = {
    "effect" = "Allow"

    "actions" = [
      "s3:GetObject",
      "s3:ListObjects",
      "s3:ListBucket",
    ]

    "resources" = [
      "arn:aws:s3:::${var.s3_secrets_bucket}*"
    ]
  }

  "statement" = {
    "effect" = "Allow"

    "actions" = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
    ]

    "resources" = [
      "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${var.submitted_responses_table_name}"
    ]
  }
}

resource "aws_iam_role_policy" "survey_runner_task" {
  name   = "${var.env}_iam_for_survey_runner_task"
  role   = "${aws_iam_role.survey_runner_task.id}"
  policy = "${data.aws_iam_policy_document.survey_runner_task.json}"
}

resource "aws_cloudwatch_log_group" "survey_runner" {
  name = "${var.env}-survey-runner"

  tags {
    Environment = "${var.env}"
  }
}

output "survey_runner_address" {
  value = "https://${aws_route53_record.survey_runner.fqdn}"
}
