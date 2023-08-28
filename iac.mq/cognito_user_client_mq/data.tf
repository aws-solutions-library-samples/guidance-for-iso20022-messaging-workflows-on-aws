data "aws_cognito_user_pools" "this" {
  name = format("%s-%s", var.q.cognito_name, local.rp2_id)
}

data "terraform_remote_state" "mq" {
  backend = "s3"
  config = {
    skip_region_validation = true

    region = data.aws_region.this.name
    bucket = var.backend_bucket[data.aws_region.this.name]
    key    = format(var.backend_pattern, "mq_broker")
  }
}
