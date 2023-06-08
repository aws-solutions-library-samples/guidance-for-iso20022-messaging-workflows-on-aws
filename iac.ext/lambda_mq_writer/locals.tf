locals {
  empty    = "{'client_id': null, 'client_secret': null}"
  empty2   = "{'rmq_host': null, 'rmq_user': null, 'rmq_pass': null}"
  cognito = jsondecode(try(data.aws_secretsmanager_secret_version.cognito.secret_string, local.empty))
  mq      = jsondecode(try(data.aws_secretsmanager_secret_version.mq.secret_string, local.empty2))
  domain  = format("%s.%s", data.aws_region.this.name, data.terraform_remote_state.mq.outputs.custom_domain)
}
