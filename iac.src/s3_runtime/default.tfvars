q = {
  bucket              = "rp2-runtime"
  # acl                 = "private"
  force_destroy       = true
  # block_access        = true
  object_lock_enabled = true
  object_lock_mode    = "COMPLIANCE"
  object_lock_days    = 36500
  object_lock_retain  = "2345-12-31T23:59:59Z"
  # object_ownership    = "BucketOwnerPreferred"
  sse_algorithm       = "AES256" # "aws:kms"
  versioning_status   = "Enabled"
  logs_prefix         = "s3_runtime_logs"
}
