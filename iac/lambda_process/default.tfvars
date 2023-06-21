q = {
  function_name = "rp2-process"
  description   = "RP2 PROCESS"
  package_type  = "Image"
  memory_size   = 128
  timeout       = 15
  publish       = false
  storage_size  = 512
  tracing_mode  = "PassThrough"
  reserved      = 20
  logging       = "INFO"

  dlq_name                = "rp2-process-lambda-dql"
  sqs_managed_sse_enabled = true
}

arch = ["arm64"]
