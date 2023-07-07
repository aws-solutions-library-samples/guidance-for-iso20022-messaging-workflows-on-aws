dependency "apigw_healthy" {
  config_path  = "../api_gateway_rest"
  skip_outputs = true
}

dependency "apigw_unhealthy" {
  config_path  = "../api_gateway_mock"
  skip_outputs = true
}

dependency "cognito" {
  config_path  = "../cognito_user_client_api"
  skip_outputs = true
}

dependency "ecr" {
  config_path  = "../ecr_recover"
  skip_outputs = true
}

dependency "iam" {
  config_path  = "../iam_role_lambda_recover"
  skip_outputs = true
}
