output "aws_account_id" {
  value = aws_cognito_user_pool_domain.this.aws_account_id
}

output "cloudfront_distribution_arn" {
  value = aws_cognito_user_pool_domain.this.cloudfront_distribution_arn
}

output "s3_bucket" {
  value = aws_cognito_user_pool_domain.this.s3_bucket
}

output "version" {
  value = aws_cognito_user_pool_domain.this.version
}

output "domain" {
  value = aws_cognito_user_pool_domain.this.domain
}
