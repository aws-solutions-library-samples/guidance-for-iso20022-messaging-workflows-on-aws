data "terraform_remote_state" "mq" {
  backend = "s3"
  config = {
    skip_region_validation = true

    region = data.aws_region.this.name
    bucket = var.backend_bucket[data.aws_region.this.name]
    key    = format(var.backend_pattern, "mq_broker")
  }
}

data "aws_secretsmanager_secret" "this" {
  name = data.terraform_remote_state.mq.outputs.secret_name
}

data "aws_secretsmanager_secret_version" "this" {
  secret_id = data.aws_secretsmanager_secret.this.id
}
