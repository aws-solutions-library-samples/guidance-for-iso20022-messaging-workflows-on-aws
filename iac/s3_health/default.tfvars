q = {
  bucket           = "rp2-health"
  force_destroy    = false
  object_name      = "health.txt"
  object_ownership = "BucketOwnerPreferred"
  acl              = "public-read"
  logs_prefix      = "s3_health_logs"
}
