output "arn" {
  value = aws_lambda_function.this.arn
}

output "invoke_arn" {
  value = aws_lambda_function.this.invoke_arn
}

output "qualified_arn" {
  value = aws_lambda_function.this.qualified_arn
}

output "qualified_invoke_arn" {
  value = aws_lambda_function.this.qualified_invoke_arn
}

output "signing_job_arn" {
  value = aws_lambda_function.this.signing_job_arn
}

output "signing_profile_version_arn" {
  value = aws_lambda_function.this.signing_profile_version_arn
}

output "last_modified" {
  value = aws_lambda_function.this.last_modified
}

output "source_code_size" {
  value = aws_lambda_function.this.source_code_size
}

output "version" {
  value = aws_lambda_function.this.version
}

output "function_name" {
  value = aws_lambda_function.this.function_name
}
