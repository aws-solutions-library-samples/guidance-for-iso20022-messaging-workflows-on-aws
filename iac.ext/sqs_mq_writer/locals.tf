locals {
  empty   = { client_id = null, client_secret = null }
  cognito = try(jsondecode(data.aws_secretsmanager_secret_version.cognito.secret_string), local.empty)
}
