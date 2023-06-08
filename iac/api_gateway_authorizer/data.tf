data "terraform_remote_state" "agw" {
  backend = "s3"
  config = {
    region = data.aws_region.this.name
    bucket = var.backend_bucket[data.aws_region.this.name]
    key    = format(var.backend_pattern, "api_gateway_rest")
  }
}

data "terraform_remote_state" "cognito" {
  backend = "s3"
  config = {
    region = data.aws_region.this.name
    bucket = var.backend_bucket[data.aws_region.this.name]
    key    = format(var.backend_pattern, "cognito_user_pool")
  }
}
