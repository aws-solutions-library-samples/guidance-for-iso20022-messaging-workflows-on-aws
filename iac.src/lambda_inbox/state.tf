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

output "function_arn" {
  value = aws_lambda_event_source_mapping.this.function_arn
}

output "state" {
  value = aws_lambda_event_source_mapping.this.state
}

output "state_transition_reason" {
  value = aws_lambda_event_source_mapping.this.state_transition_reason
}

output "uuid" {
  value = aws_lambda_event_source_mapping.this.uuid
}
