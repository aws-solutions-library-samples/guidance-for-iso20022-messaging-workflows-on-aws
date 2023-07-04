dependency "iam" {
  config_path  = "../iam_role_scheduler_timeout"
  skip_outputs = true
}

dependency "iam" {
  config_path  = "../lambda_timeout"
  skip_outputs = true
}
