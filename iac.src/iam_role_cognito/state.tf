output "arn" {
  value = aws_iam_role.this.arn
}

output "id" {
  value = aws_iam_role.this.id
}

output "unique_id" {
  value = aws_iam_role.this.unique_id
}

output "create_date" {
  value = aws_iam_role.this.create_date
}

output "name" {
  value = aws_iam_role.this.name
}

output "external_id" {
  value = local.external_id
}
