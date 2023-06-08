data "terraform_remote_state" "cognito" {
  backend = "s3"
  config = {
    region = data.aws_region.this.name
    bucket = var.backend_bucket[data.aws_region.this.name]
    key    = format(var.backend_pattern, "cognito_user_pool")
  }
}

data "terraform_remote_state" "iam_logs" {
  backend = "s3"
  config = {
    region = element(keys(var.backend_bucket), 0)
    bucket = var.backend_bucket[element(keys(var.backend_bucket), 0)]
    key    = format(var.backend_pattern, "iam_role_agw_logs")
  }
}

data "terraform_remote_state" "iam_sqs" {
  backend = "s3"
  config = {
    region = element(keys(var.backend_bucket), 0)
    bucket = var.backend_bucket[element(keys(var.backend_bucket), 0)]
    key    = format(var.backend_pattern, "iam_role_agw_sqs")
  }
}

data "terraform_remote_state" "lambda_health" {
  backend = "s3"
  config = {
    region = data.aws_region.this.name
    bucket = var.backend_bucket[data.aws_region.this.name]
    key    = format(var.backend_pattern, "lambda_health")
  }
}
