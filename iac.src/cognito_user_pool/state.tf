output "arn" {
  value = aws_cognito_user_pool.this.arn
}

output "id" {
  value = aws_cognito_user_pool.this.id
}

output "domain" {
  value = aws_cognito_user_pool.this.domain
}

output "custom_domain" {
  value = aws_cognito_user_pool.this.custom_domain
}

output "endpoint" {
  value = aws_cognito_user_pool.this.endpoint
}

output "creation_date" {
  value = aws_cognito_user_pool.this.creation_date
}

output "last_modified_date" {
  value = aws_cognito_user_pool.this.last_modified_date
}
