##########################################
# validate acm certificate and s3 bucket #
##########################################
variable "bucket" {
  type    = string
  default = "rp2-backend-us-east-1"
}

variable "domain" {
  type    = string
  default = "example.com"
}

data "aws_s3_bucket" "this" {
  bucket = var.bucket
}

data "aws_acm_certificate" "this" {
  domain   = var.domain
  statuses = ["ISSUED"]
}

data "aws_acm_certificate" "that" {
  provider = aws.glob
  domain   = var.domain
  statuses = ["ISSUED"]
}

provider "aws" {
  alias  = "glob"
  region = "us-east-1"
}

resource "aws_s3_object" "this" {
  bucket = data.aws_s3_bucket.this.bucket
  key    = "validate.tf"
  source = "validate.tf"
  etag = filemd5("validate.tf")
}

output "bucket" {
  value = data.aws_s3_bucket.this.bucket
}

output "object" {
  value = aws_s3_object.this.id
}

output "domain" {
  value = data.aws_acm_certificate.this.domain
}
