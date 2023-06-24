output "id" {
  value = aws_secretsmanager_secret.this.id
}

output "arn" {
  value = aws_secretsmanager_secret.this.arn
}

output "replica" {
  value = aws_secretsmanager_secret.this.replica
}

output "version_id" {
  value = aws_secretsmanager_secret_version.this.id
}

output "version_arn" {
  value = aws_secretsmanager_secret_version.this.arn
}

output "secret_name" {
  value = aws_secretsmanager_secret.this.name
}
