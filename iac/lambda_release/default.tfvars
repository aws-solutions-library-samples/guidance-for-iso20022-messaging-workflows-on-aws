q = {
  function_name = "rp2-release"
  description   = "RP2 RELEASE"
  package_type  = "Image"
  memory_size   = 128
  timeout       = 15
  publish       = false
  storage_size  = 512
  tracing_mode  = "PassThrough"
  reserved      = 20
  logging       = "INFO"

  dlq_name                = "rp2-release-lambda-dql"
  sqs_managed_sse_enabled = true
}

arch = ["arm64"]
