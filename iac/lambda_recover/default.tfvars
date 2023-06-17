q = {
  function_name = "rp2-recover"
  description   = "RP2 RECOVER"
  package_type  = "Image"
  memory_size   = 128
  timeout       = 15
  publish       = false
  storage_size  = 512
  tracing_mode  = "PassThrough"
  reserved      = 20
  logging       = "DEBUG"

  dlq_name                = "rp2-recover-lambda-dql"
  sqs_managed_sse_enabled = true
}

arch = ["arm64"]
