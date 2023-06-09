q = {
  origin_type      = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
  enabled          = true
  is_ipv6_enabled  = true
  compress         = true
  min_ttl          = 0
  max_ttl          = 0
  default_ttl      = 0
  default_object   = "health.txt"
  allowed_methods  = "HEAD,GET"
  cached_methods   = "HEAD,GET"
  cache_policy_id  = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  viewer_policy    = "redirect-to-https"
  viewer_cert      = true
  minimum_version  = "TLSv1"
  # minimum_version  = "TLSv1.2_2018"
  logging_prefix   = "cloudfront"
}

# Not Supported Regions for CF logs to S3
# https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html#access-logs-choosing-s3-bucket
r = [
  "af-south-1",
  "ap-east-1",
  "ap-south-2",
  "ap-southeast-3",
  "ap-southeast-4",
  "eu-south-1",
  "eu-south-2",
  "eu-central-2",
  "me-south-1",
  "me-central-1"
]
