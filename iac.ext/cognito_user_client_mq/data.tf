data "aws_cognito_user_pools" "this" {
  name = var.q.cognito_name
}

data "terraform_remote_state" "mq" {
  backend = "s3"
  config = {
    region = data.aws_region.this.name
    bucket = var.backend_bucket[data.aws_region.this.name]
    key    = format(var.backend_pattern, "mq_broker")
  }
}
