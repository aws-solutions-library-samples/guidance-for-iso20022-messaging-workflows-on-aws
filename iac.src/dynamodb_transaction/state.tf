output "arn" {
  value = length(aws_dynamodb_table.this.*.arn) > 0 ? element(aws_dynamodb_table.this.*.arn, 0) : null
}

output "id" {
  value = length(aws_dynamodb_table.this.*.id) > 0 ? element(aws_dynamodb_table.this.*.id, 0) : null
}

output "stream_arn" {
  value = length(aws_dynamodb_table.this.*.stream_arn) > 0 ? element(aws_dynamodb_table.this.*.stream_arn, 0) : null
}

output "stream_label" {
  value = length(aws_dynamodb_table.this.*.stream_label) > 0 ? element(aws_dynamodb_table.this.*.stream_label, 0) : null
}
