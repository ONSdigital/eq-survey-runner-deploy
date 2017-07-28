resource "aws_cloudwatch_metric_alarm" "survey_runner_high_cpu" {
  alarm_name          = "${var.env}-survey-runner-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "60"

  dimensions {
    ClusterName = "${data.aws_ecs_cluster.ecs-cluster.cluster_name}"
    ServiceName = "${aws_ecs_service.survey_runner.name}"
  }

  alarm_description = "This metric monitors Survey Runner ECS Service cpu utilization"
  alarm_actions     = ["${aws_appautoscaling_policy.survey_runner_scale.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "survey_runner_low_cpu" {
  alarm_name          = "${var.env}-survey-runner-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "5"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "20"

  dimensions {
    ClusterName = "${data.aws_ecs_cluster.ecs-cluster.cluster_name}"
    ServiceName = "${aws_ecs_service.survey_runner.name}"
  }

  alarm_description = "This metric monitors ECS Instance cpu utilization"
  alarm_actions     = ["${aws_appautoscaling_policy.survey_runner_scale.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "no_remaining_database_connections" {
  alarm_name          = "${var.env}-survey-runner-no_remaining_database_connections"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "${aws_cloudwatch_log_metric_filter.no_database_connections_remaining.metric_transformation.0.name}"
  namespace           = "${aws_cloudwatch_log_metric_filter.no_database_connections_remaining.metric_transformation.0.namespace}"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "1"
  alarm_description   = "The number of database connections has been exhausted"
  alarm_actions       = ["arn:aws:sns:eu-west-1:${data.aws_caller_identity.current.account_id}:${var.env}-slack-alert"]
}

resource "aws_cloudwatch_log_metric_filter" "no_database_connections_remaining" {
  name           = "${var.env}_no_remaining_database_connections"
  pattern        = "\"remaining connection slots are reserved for non-replication superuser connections\""
  log_group_name = "${aws_cloudwatch_log_group.survey_runner.name}"

  metric_transformation {
    name      = "${var.env}_no_remaining_database_connections"
    namespace = "${var.env}_SurveyRunner"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "jwt_kid_in_use" {
  name           = "jwt_kids_in_use"
  pattern        = "{$.event = \"Decoding JWT\"}"
  log_group_name = "${aws_cloudwatch_log_group.survey_runner.name}"

  metric_transformation {
    name      = "JWT_KID"
    namespace = "${var.env}_SurveyRunner"
    value     = "$.kid"
  }
}

resource "aws_cloudwatch_log_metric_filter" "jwe_kid_in_use" {
  name           = "jwe_kids_in_use"
  pattern        = "{$.event = \"Decrypting JWE\"}"
  log_group_name = "${aws_cloudwatch_log_group.survey_runner.name}"

  metric_transformation {
    name      = "JWE_KID"
    namespace = "${var.env}_SurveyRunner"
    value     = "$.kid"
  }
}
