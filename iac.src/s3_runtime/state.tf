output "arn" {
  value = aws_s3_bucket.this.arn
}

output "id" {
  value = aws_s3_bucket.this.id
}

output "bucket_domain_name" {
  value = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  value = aws_s3_bucket.this.bucket_regional_domain_name
}

output "hosted_zone_id" {
  value = aws_s3_bucket.this.hosted_zone_id
}

output "region" {
  value = aws_s3_bucket.this.region
}

output "region2" {
  value = (
    aws_s3_bucket.this.region == element(keys(var.backend_bucket), 0)
    ? element(keys(var.backend_bucket), 1) : element(keys(var.backend_bucket), 0)
  )
}

output "domain" {
  value = format("%s.s3.%s.amazonaws.com", aws_s3_bucket.this.id, aws_s3_bucket.this.region)
}

output "custom_domain" {
  value = var.custom_domain
}

output "rp2_id" {
  value = local.rp2_id
}
