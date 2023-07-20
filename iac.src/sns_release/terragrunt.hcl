dependency "lambda" {
  config_path  = "../lambda_release"
  skip_outputs = true
}

dependency "s3" {
  config_path  = "../s3_runtime"
  skip_outputs = true
}
