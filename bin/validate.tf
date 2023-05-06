##########################################
# validate acm certificate and s3 bucket #
##########################################
variable "custom_domain" {
  type    = string
  default = "example.com"
}

variable "resource_prefix" {
  type    = string
  default = "example-resource"
}

data "aws_s3_bucket" "this" {
  bucket = var.resource_prefix
}

data "aws_acm_certificate" "this" {
  domain   = var.custom_domain
  statuses = ["ISSUED"]
}

output "bucket" {
  value = data.aws_s3_bucket.this.bucket
}

output "domain" {
  value = data.aws_acm_certificate.this.domain
}

resource "random_string" "this" {
  length  = 8
  upper   = false
  special = false
}

#################################
# create kms key: alias/aws/acm #
#################################
resource "aws_acm_certificate" "this" {
  domain_name       = var.custom_domain
  validation_method = "EMAIL"

  lifecycle {
    create_before_destroy = true
  }
}

######################################
# create kms key: alias/aws/dynamodb #
######################################
resource "aws_dynamodb_table" "this" {
  #checkov:skip=CKV_AWS_119:KMS Customer Managed CMK not needed - overwritten decision

  name           = format("%s-%s", var.resource_prefix, random_string.this.result)
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "UserId"

  attribute {
    name = "UserId"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

#################################
# create kms key: alias/aws/ebs #
#################################
# resource "aws_ebs_encryption_by_default" "this" {
#   enabled = true
# }

#################################
# create kms key: alias/aws/ecr #
#################################
resource "aws_ecr_repository" "this" {
  name                 = format("%s-%s", var.resource_prefix, random_string.this.result)
  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "KMS"
  }

  image_scanning_configuration {
    scan_on_push = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

################################
# create kms key: alias/aws/s3 #
################################
resource "aws_s3_bucket" "this" {
  #checkov:skip=CKV_AWS_18:Logging not needed -- access logging is skipped
  #checkov:skip=CKV_AWS_21:Versioning not needed -- object versioning is skipped
  #checkov:skip=CKV_AWS_144:Replication not needed -- cross region replication is skipped
  #checkov:skip=CKV_AWS_145:Encryption not needed -- server side encryption is skipped
  #checkov:skip=CKV2_AWS_6:Public access not needed -- public access block is skipped
  #checkov:skip=CKV2_AWS_61:Lifecycle not needed -- lifecycle policy is skipped
  #checkov:skip=CKV2_AWS_62:Event notification not needed -- triggering events is skipped

  bucket = format("%s-%s", var.resource_prefix, random_string.this.result)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

#################################
# create kms key: alias/aws/sns #
#################################
resource "aws_sns_topic" "this" {
  name              = format("%s-%s.fifo", var.resource_prefix, random_string.this.result)
  fifo_topic        = true
  kms_master_key_id = "alias/aws/sns"

  lifecycle {
    create_before_destroy = true
  }
}

#################################
# create kms key: alias/aws/sqs #
#################################
resource "aws_sqs_queue" "this" {
  name              = format("%s-%s.fifo", var.resource_prefix, random_string.this.result)
  fifo_queue        = true
  kms_master_key_id = "alias/aws/sqs"

  lifecycle {
    create_before_destroy = true
  }
}
