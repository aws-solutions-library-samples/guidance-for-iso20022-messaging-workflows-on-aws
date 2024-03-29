data "aws_ecr_image" "this" {
  repository_name = data.terraform_remote_state.ecr.outputs.name
  image_tag       = "latest"
}

data "aws_secretsmanager_secret" "cognito" {
  name = data.terraform_remote_state.cognito.outputs.secret_name
}

data "aws_secretsmanager_secret_version" "cognito" {
  secret_id = data.aws_secretsmanager_secret.cognito.id
}

data "aws_secretsmanager_secret" "mq" {
  name = data.terraform_remote_state.mq.outputs.secret_name
}

data "aws_secretsmanager_secret_version" "mq" {
  secret_id = data.aws_secretsmanager_secret.mq.id
}

data "terraform_remote_state" "cognito" {
  backend = "s3"
  config = {
    skip_region_validation = true

    region = data.aws_region.this.name
    bucket = var.backend_bucket[data.aws_region.this.name]
    key    = format(var.backend_pattern, "cognito_user_client_mq")
  }
}

data "terraform_remote_state" "ecr" {
  backend = "s3"
  config = {
    skip_region_validation = true

    region = data.aws_region.this.name
    bucket = var.backend_bucket[data.aws_region.this.name]
    key    = format(var.backend_pattern, "ecr_mq_reader")
  }
}

data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    skip_region_validation = true

    region = data.aws_region.this.name
    bucket = var.backend_bucket[data.aws_region.this.name]
    key    = format(var.backend_pattern, "iam_role_lambda_mq_reader")
  }
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
