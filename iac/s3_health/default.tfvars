q = {
  bucket           = "rp2-health"
  force_destroy    = false
  block_access     = true
  object_name      = "health.txt"
  object_ownership = "BucketOwnerPreferred"
  acl              = "public-read"
  logs_prefix      = "s3_health_logs"
}
