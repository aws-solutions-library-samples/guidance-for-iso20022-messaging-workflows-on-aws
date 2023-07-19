q = {
  name          = "rp2-outbox"
  description   = "RP2 OUTBOX"
  package_type  = "Image"
  architecture  = "arm64"
  memory_size   = 128
  timeout       = 15
  publish       = false
  storage_size  = 512
  tracing_mode  = "PassThrough"
  reserved      = 20
  logging       = "INFO"

  sqs_managed_sse_enabled = true
  secrets_manager_ttl     = 300
}
