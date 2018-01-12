variable "env" {
  description = "The environment name, used to identify your environment"
}

variable "aws_secret_key" {
  description = "Amazon Web Service Secret Key"
}

variable "aws_access_key" {
  description = "Amazon Web Service Access Key"
}

variable "ecs_cluster_name" {
  description = "The name of the survey runner ECS cluster"
}

variable "aws_alb_listener_arn" {
  description = "The ARN of the survey runner ALB"
}

# DNS

variable "dns_zone_name" {
  description = "Amazon Route53 DNS zone name"
  default     = "eq.ons.digital."
}

# Survey runner
variable "docker_registry" {
  description = "The docker repository for the Survey Runner image"
  default     = "onsdigital"
}

variable "survey_runner_tag" {
  description = "The tag for the Survey Runner image to run"
  default     = "latest"
}

variable "aws_default_region" {
  description = "The default region for AWS Services"
  default     = "eu-west-1"
}

variable "survey_runner_min_tasks" {
  description = "The minimum number of Survey Runner tasks to run"
  default     = "3"
}

variable "survey_runner_max_tasks" {
  description = "The Maximum number of Survey Runner tasks to run"
  default     = "50"
}

variable "eq_log_level" {
  description = "The Survey Runner logging level (One of ['CRITICAL', 'ERROR', 'WARNING', 'INFO', 'DEBUG'])"
  default     = "INFO"
}

variable "s3_secrets_bucket" {
  description = "The S3 bucket name that contains the secrets"
}

variable "secrets_file_name" {
  description = "The filename of the file containing the application secrets"
  default     = "secrets.yml"
}

variable "keys_file_name" {
  description = "The filename of the file containing the application keys"
  default     = "keys.yml"
}

variable "google_analytics_code" {
  description = "The google analytics UA Code"
}

# Database
variable "database_host" {
  description = "The hostname of the postgres database"
}

variable "database_port" {
  description = "The port of the postgres database"
}

variable "database_name" {
  description = "The name of the database"
}

# RabbitMQ
variable "rabbitmq_ip_prime" {
  description = "Static IP of prime rabbitmq server"
}

variable "rabbitmq_ip_failover" {
  description = "Static IP of secondary failover rabbitmq server"
}

variable "message_queue_name" {
  description = "RabbitMQ submission queue name"
  default     = "submit_q"
}

variable "respondent_account_url" {
  description = "The url for the respondent log in that will be used to navigate to preprod"
  default     = "https://survey.ons.gov.uk/"
}

variable "submitted_responses_table_name" {
  description = "Table name of table used for storing Submitted Responses"
}
