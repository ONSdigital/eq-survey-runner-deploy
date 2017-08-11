### eq-survey-runner-deploy

This repository hold the code that is responsible for deploying [Survey Runner](https://github.com/ONSdigital/eq-survey-runner)

These terraform scripts are used to deploy the Survey Runner Docker images to an AWS ECS cluster.

To deploy Survey Runner add the following module to your terraform scripts

```
module "survey-runner" {
  source                  = "github.com/ONSdigital/eq-survey-runner-deploy"
  env                     = "${var.env}"
  aws_access_key          = "${var.aws_access_key}"
  aws_secret_key          = "${var.aws_secret_key}"
  dns_zone_name           = "${var.dns_zone_name}"
  ecs_cluster_name        = "${module.survey-runner-ecs.ecs_cluster_name}"
  aws_alb_listener_arn    = "${module.survey-runner-ecs.aws_alb_listener_arn}"
  s3_secrets_bucket       = "${var.survey_runner_s3_secrets_bucket}"
  database_host           = "${module.survey-runner-database.database_address}"
  database_port           = "${module.survey-runner-database.database_port}"
  database_name           = "${var.database_name}"
  rabbitmq_ip_prime       = "${module.survey-runner-queue.rabbitmq_ip_prime}"
  rabbitmq_ip_failover    = "${module.survey-runner-queue.rabbitmq_ip_failover}"
  google_analytics_code   = "${var.google_analytics_code}"
  survey_runner_min_tasks = "${var.survey_runner_min_tasks}"
  docker_registry         = "${var.docker_registry}"
  survey_runner_tag       = "${var.survey_runner_tag}"
  secrets_file_name       = "${var.secrets_file_name}"
}
```