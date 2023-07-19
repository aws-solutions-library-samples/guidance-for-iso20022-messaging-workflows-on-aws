locals {
  cognito = try(jsondecode(data.aws_secretsmanager_secret_version.cognito.secret_string), { RP2_AUTH_CLIENT_ID = null })
  rp2_id = data.terraform_remote_state.mq.outputs.rp2_id
}
