data "terraform_remote_state" "cognito" {
  backend = "s3"
  config = {
    skip_region_validation = true

    region = data.aws_region.this.name
    bucket = var.backend_bucket[data.aws_region.this.name]
    key    = format(var.backend_pattern, "cognito_user_client_api")
  }
}

data "terraform_remote_state" "ecr" {
  backend = "s3"
  config = {
    skip_region_validation = true

    region = data.aws_region.this.name
    bucket = var.backend_bucket[data.aws_region.this.name]
    key    = format(var.backend_pattern, "ecr_recover")
  }
}

data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    skip_region_validation = true

    region = element(keys(var.backend_bucket), 0)
    bucket = var.backend_bucket[element(keys(var.backend_bucket), 0)]
    key    = format(var.backend_pattern, "iam_role_lambda")
  }
}

data "terraform_remote_state" "s3" {
  backend = "s3"
  config = {
    skip_region_validation = true

    region = data.aws_region.this.name
    bucket = var.backend_bucket[data.aws_region.this.name]
    key    = format(var.backend_pattern, "s3_runtime")
  }
}

data "aws_ecr_image" "this" {
  repository_name = data.terraform_remote_state.ecr.outputs.name
  image_tag       = "latest"
}

data "aws_secretsmanager_secret" "this" {
  # count = length(keys(var.backend_bucket))
  # name  = replace(data.terraform_remote_state.cognito.outputs.secret_name, data.aws_region.this.name, element(keys(var.backend_bucket), count.index))
  name  = data.terraform_remote_state.cognito.outputs.secret_name
}

data "aws_secretsmanager_secret_version" "this" {
  # count     = length(try(data.aws_secretsmanager_secret.this.*.id, []))
  # secret_id = element(try(data.aws_secretsmanager_secret.this.*.id, []), count.index)
  secret_id = data.aws_secretsmanager_secret.this.id
}
