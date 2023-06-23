output "arn" {
  value = aws_api_gateway_domain_name.this.*.arn
}

output "id" {
  value = aws_api_gateway_domain_name.this.*.id
}

output "regional_zone_id" {
  value = aws_api_gateway_domain_name.this.*.regional_zone_id
}

output "regional_domain_name" {
  value = aws_api_gateway_domain_name.this.*.regional_domain_name
}

output "certificate_upload_date" {
  value = aws_api_gateway_domain_name.this.*.certificate_upload_date
}

output "cloudfront_zone_id" {
  value = aws_api_gateway_domain_name.this.*.cloudfront_zone_id
}

output "cloudfront_domain_name" {
  value = aws_api_gateway_domain_name.this.*.cloudfront_domain_name
}
