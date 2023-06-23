locals {
  empty   = "{'client_id': null, 'client_secret': null}"
  cognito = jsondecode(try(data.aws_secretsmanager_secret_version.this.secret_string, local.empty))
  # cognito2 = jsondecode(try(data.aws_secretsmanager_secret_version.this.1.secret_string, local.empty))
  domain  = format("%s.%s", data.aws_region.this.name, data.terraform_remote_state.s3.outputs.custom_domain)
}
