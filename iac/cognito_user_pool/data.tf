data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    region = element(keys(var.backend_bucket), 0)
    bucket = var.backend_bucket[element(keys(var.backend_bucket), 0)]
    key    = format(var.backend_pattern, "iam_role_cognito")
  }
}

data "aws_acm_certificate" "this" {
  domain   = var.custom_domain
  statuses = ["ISSUED"]
}
