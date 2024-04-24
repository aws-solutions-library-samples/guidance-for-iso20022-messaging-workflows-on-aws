data "aws_region" "this" {}
data "aws_caller_identity" "this" {}

provider "aws" {
  allowed_account_ids    = try(split(",", var.account), null)
  skip_region_validation = true

  default_tags {
    tags = {
      Project        = "rp2"
      Environment    = "default"
      UniqueId       = var.rp2_id
      Domain         = var.custom_domain
      Contact        = "github.com/eistrati"
      awsApplication = try(var.app_arn, null)
    }
  }
}

terraform {
  required_version = ">= 1.2.0, <1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.46.0"
    }
  }
}

variable "account" {
  type    = string
  default = null
}

variable "app_arn" {
  type    = string
  default = ""
}

variable "backend_bucket" {
  type = map(string)
  default = {
    "us-east-1" = "rp2-backend-us-east-1"
    "us-west-2" = "rp2-backend-us-west-2"
  }
}

variable "backend_pattern" {
  type    = string
  default = "terraform/github/rp2/%s/terraform.tfstate"
}

variable "custom_domain" {
  type    = string
  default = "example.com"
}

variable "rp2_id" {
  type    = string
  default = null
}
