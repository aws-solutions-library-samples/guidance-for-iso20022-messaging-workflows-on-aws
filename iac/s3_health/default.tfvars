q = {
  bucket           = "rp2-health"
  force_destroy    = false
  block_access     = true
  object_name      = "rp2-health"
  object_ext       = "txt"
  object_ownership = "BucketOwnerPreferred"
  acl              = "public-read"
  logs_prefix      = "s3_health_logs"
}
