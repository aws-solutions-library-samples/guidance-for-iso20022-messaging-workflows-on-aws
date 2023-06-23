output "arn" {
  value = length(aws_iam_role.this.*.arn) > 0 ? element(aws_iam_role.this.*.arn, 0) : null
}

output "id" {
  value = length(aws_iam_role.this.*.id) > 0 ? element(aws_iam_role.this.*.id, 0) : null
}

output "unique_id" {
  value = length(aws_iam_role.this.*.unique_id) > 0 ? element(aws_iam_role.this.*.unique_id, 0) : null
}

output "create_date" {
  value = length(aws_iam_role.this.*.create_date) > 0 ? element(aws_iam_role.this.*.create_date, 0) : null
}

output "name" {
  value = length(aws_iam_role.this.*.name) > 0 ? element(aws_iam_role.this.*.name, 0) : null
}

output "external_id" {
  value = local.external_id
}
