dependency "cognito" {
  config_path  = "../cognito_user_client_api"
  skip_outputs = true
}

dependency "ecr" {
  config_path  = "../ecr_outbox"
  skip_outputs = true
}

dependency "iam" {
  config_path  = "../iam_role_lambda_outbox"
  skip_outputs = true
}
