q = {
  bucket              = "rp2-runtime"
  force_destroy       = true
  block_access        = true
  object_lock_enabled = true
  object_lock_mode    = "COMPLIANCE"
  object_lock_retain  = "2345-12-31T23:59:59Z"
  object_ownership    = "BucketOwnerPreferred"
  acl                 = "private"
}
