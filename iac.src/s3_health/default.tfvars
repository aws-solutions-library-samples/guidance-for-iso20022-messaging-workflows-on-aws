q = {
  bucket           = "rp2-health"
  force_destroy    = true
  block_access     = true
  object_name      = "rp2-health"
  object_ext       = "txt"
  object_ownership = "BucketOwnerPreferred"
  logs_prefix      = "s3_health_logs"
}
