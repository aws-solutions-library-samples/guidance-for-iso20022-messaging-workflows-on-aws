dependency "cognito" {
  config_path  = "../cognito_user_pool"
  skip_outputs = true
}

dependency "domain" {
  config_path  = "../cognito_user_domain"
  skip_outputs = true
}

dependency "s3" {
  config_path  = "../s3_runtime"
  skip_outputs = true
}
