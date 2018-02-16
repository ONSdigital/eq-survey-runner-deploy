resource "aws_alb_target_group" "survey_runner_static" {
  name     = "${var.env}-sr-static"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${data.aws_alb.eq.vpc_id}"

  health_check = {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 2
    path                = "/"
  }

  tags {
    Environment = "${var.env}"
  }
}

resource "aws_alb_listener_rule" "survey_runner_static" {
  listener_arn = "${var.aws_alb_listener_arn}"
  priority     = 5

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.survey_runner_static.arn}"
  }

  condition = [
    {
      field  = "host-header"
      values = ["${aws_route53_record.survey_runner.name}"]
    },
    {
      field  = "path-pattern"
      values = ["/s/*"]
    },
  ]
}

data "template_file" "survey_runner_static" {
  template = "${file("${path.module}/task-definitions/survey-runner-static.json")}"

  vars {
    LOG_GROUP          = "${aws_cloudwatch_log_group.survey_runner_static.name}"
    CONTAINER_REGISTRY = "${var.docker_registry}"
    CONTAINER_TAG      = "${var.survey_runner_tag}"
  }
}

resource "aws_ecs_task_definition" "survey_runner_static" {
  family                = "${var.env}-survey-runner-static"
  container_definitions = "${data.template_file.survey_runner_static.rendered}"
}

resource "aws_ecs_service" "survey_runner_static" {
  depends_on = [
    "aws_alb_listener_rule.survey_runner_static",
  ]

  name            = "${var.env}-survey-runner-static"
  cluster         = "${data.aws_ecs_cluster.ecs-cluster.id}"
  task_definition = "${aws_ecs_task_definition.survey_runner_static.family}"
  desired_count   = "${var.survey_runner_static_min_tasks}"
  iam_role        = "${aws_iam_role.survey_runner_static.arn}"

  placement_strategy {
    type  = "spread"
    field = "host"
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.survey_runner_static.arn}"
    container_name   = "survey-runner-static"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = ["placement_strategy", "desired_count"]
  }
}

resource "aws_iam_role" "survey_runner_static" {
  name = "${var.env}_iam_for_survey_runner_static"

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

data "aws_iam_policy_document" "survey_runner_static" {
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

resource "aws_iam_role_policy" "survey_runner_static" {
  name   = "${var.env}_iam_for_survey_runner"
  role   = "${aws_iam_role.survey_runner_static.id}"
  policy = "${data.aws_iam_policy_document.survey_runner_static.json}"
}

resource "aws_cloudwatch_log_group" "survey_runner_static" {
  name = "${var.env}-survey-runner-static"

  tags {
    Environment = "${var.env}"
  }
}
