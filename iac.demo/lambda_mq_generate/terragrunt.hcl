dependency "cognito" {
  config_path  = "../cognito_user_client_mq"
  skip_outputs = true
}

dependency "ecr" {
  config_path  = "../ecr_mq_generator"
  skip_outputs = true
}

dependency "mq" {
  config_path  = "../mq_broker"
  skip_outputs = true
}
