dependency "cognito" {
  config_path  = "../cognito_user_client_api"
  skip_outputs = true
}

dependency "ecr" {
  config_path  = "../ecr_release"
  skip_outputs = true
}

dependency "iam" {
  config_path  = "../iam_role_lambda_release"
  skip_outputs = true
}

dependency "sqs" {
  config_path  = "../sqs_release"
  skip_outputs = true
}
