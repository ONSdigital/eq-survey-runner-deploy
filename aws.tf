terraform {
  backend "s3" {
    region = "eu-west-1"
  }
}

provider "aws" {
  version = ">= 1.9.0"

  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "eu-west-1"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {
  current = true
}

data "aws_ecs_cluster" "ecs-cluster" {
  cluster_name = "${var.ecs_cluster_name}"
}

data "aws_lb_listener" "eq" {
  load_balancer_arn = "${data.aws_lb.eq.arn}"
  port              = "443"
}

data "aws_lb" "eq" {
  arn = "${var.aws_alb_arn}"
}

data "aws_route53_zone" "dns_zone" {
  name = "${var.dns_zone_name}"
}
