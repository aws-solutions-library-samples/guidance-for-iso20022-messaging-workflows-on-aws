dependency "apigw" {
  config_path  = "../api_gateway_rest"
  skip_outputs = true
}

dependency "s3" {
  config_path  = "../s3_runtime"
  skip_outputs = true
}
