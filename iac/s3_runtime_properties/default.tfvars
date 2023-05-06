q = {
  versioning_status = "Enabled"
  sse_algorithm     = "AES256" # "aws:kms"
  object_lock_mode  = "COMPLIANCE"
  object_lock_days  = 36500
  object_ownership  = "BucketOwnerPreferred"
  target_prefix     = "s3_logs"
}
