q = {
  bucket              = "rp2-runtime"
  force_destroy       = true
  object_lock_enabled = true
  object_lock_mode    = "COMPLIANCE"
  object_lock_days    = 36500
  object_lock_retain  = "2345-12-31T23:59:59Z"
  sse_algorithm       = "AES256" # "aws:kms"
  versioning_status   = "Enabled"
  logs_prefix         = "s3_runtime_logs"
}
