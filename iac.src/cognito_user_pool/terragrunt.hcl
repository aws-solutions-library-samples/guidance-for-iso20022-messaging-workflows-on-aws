dependency "iam" {
  config_path  = "../iam_role_cognito"
  skip_outputs = true
}

dependency "s3" {
  config_path  = "../s3_runtime"
  skip_outputs = true
}
