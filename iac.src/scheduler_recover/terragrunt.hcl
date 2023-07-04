dependency "iam" {
  config_path  = "../iam_role_scheduler_recover"
  skip_outputs = true
}

dependency "iam" {
  config_path  = "../lambda_recover"
  skip_outputs = true
}
