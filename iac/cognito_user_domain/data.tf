data "terraform_remote_state" "cognito" {
  backend = "s3"
  config = {
    region = data.aws_region.this.name
    bucket = var.backend_bucket[data.aws_region.this.name]
    key    = format(var.backend_pattern, "cognito_user_pool")
  }
}

data "aws_acm_certificate" "this" {
  provider = aws.glob
  domain   = var.custom_domain
  statuses = ["ISSUED"]
}

provider "aws" {
  alias  = "glob"
  region = "us-east-1"

  skip_region_validation = true
}
