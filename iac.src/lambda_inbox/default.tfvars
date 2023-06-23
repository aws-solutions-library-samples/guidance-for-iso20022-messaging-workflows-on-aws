q = {
  function_name = "rp2-inbox"
  description   = "RP2 INBOX"
  package_type  = "Image"
  architecture  = "arm64"
  memory_size   = 128
  timeout       = 15
  publish       = false
  storage_size  = 512
  tracing_mode  = "PassThrough"
  reserved      = 20
  logging       = "INFO"

  dlq_name                = "rp2-inbox-lambda-dql"
  sqs_managed_sse_enabled = true
  secrets_manager_ttl     = 300
}
