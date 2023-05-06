dependency "cf" {
  config_path  = "../cloudfront_runtime"
  skip_outputs = true
}

dependency "s3" {
  config_path  = "../s3_runtime"
  skip_outputs = true
}
