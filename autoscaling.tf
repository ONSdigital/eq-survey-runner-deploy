resource "aws_appautoscaling_target" "ecs_survey_runner_target" {
  min_capacity       = "${var.survey_runner_min_tasks}"
  max_capacity       = "${var.survey_runner_max_tasks}"
  resource_id        = "service/${data.aws_ecs_cluster.ecs-cluster.cluster_name}/${aws_ecs_service.survey_runner.name}"
  role_arn           = "${aws_iam_role.survey_runner_scaling.arn}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "survey_runner_scale" {
  adjustment_type         = "ChangeInCapacity"
  cooldown                = 60
  metric_aggregation_type = "Maximum"
  name                    = "${var.env}-survey-runner-scaling"
  resource_id             = "service/${data.aws_ecs_cluster.ecs-cluster.cluster_name}/${aws_ecs_service.survey_runner.name}"
  scalable_dimension      = "ecs:service:DesiredCount"
  service_namespace       = "ecs"

  step_adjustment {
    metric_interval_lower_bound = 0
    metric_interval_upper_bound = 10
    scaling_adjustment          = 1
  }

  step_adjustment {
    metric_interval_lower_bound = 10
    metric_interval_upper_bound = 20
    scaling_adjustment          = 2
  }

  step_adjustment {
    metric_interval_lower_bound = 20
    scaling_adjustment          = 3
  }

  step_adjustment {
    metric_interval_upper_bound = 0
    scaling_adjustment          = -1
  }

  depends_on = [
    "aws_appautoscaling_target.ecs_survey_runner_target",
    "data.aws_iam_policy_document.survey_runner_scaling"
  ]
}

resource "aws_iam_role" "survey_runner_scaling" {
  name = "${var.env}_iam_for_survey_runner_scaling"

  depends_on = ["data.aws_iam_policy_document.survey_runner_scaling"]

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["application-autoscaling.amazonaws.com"]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "survey_runner_scaling" {
  "statement" = {
    "effect" = "Allow"

    "actions" = [
      "application-autoscaling:RegisterScalableTarget",
      "ecs:UpdateService",
      "cloudwatch:DescribeAlarms",
      "ecs:DescribeServices",
    ]

    "resources" = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "survey_runner_scaling" {
  name   = "${var.env}_iam_for_survey_runner_scaling"
  role   = "${aws_iam_role.survey_runner_scaling.id}"
  policy = "${data.aws_iam_policy_document.survey_runner_scaling.json}"
}
