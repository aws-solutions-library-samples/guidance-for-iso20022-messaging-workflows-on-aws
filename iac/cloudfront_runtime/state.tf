output "id" {
  value = aws_cloudfront_distribution.this.id
}

output "arn" {
  value = aws_cloudfront_distribution.this.arn
}

output "caller_reference" {
  value = aws_cloudfront_distribution.this.caller_reference
}

output "status" {
  value = aws_cloudfront_distribution.this.status
}

output "domain_name" {
  value = aws_cloudfront_distribution.this.domain_name
}

output "last_modified_time" {
  value = aws_cloudfront_distribution.this.last_modified_time
}

output "etag" {
  value = aws_cloudfront_distribution.this.etag
}

output "hosted_zone_id" {
  value = aws_cloudfront_distribution.this.hosted_zone_id
}

output "default_object" {
  value = aws_cloudfront_distribution.this.default_root_object
}

output "oac_id" {
  value = aws_cloudfront_origin_access_control.this.id
}
