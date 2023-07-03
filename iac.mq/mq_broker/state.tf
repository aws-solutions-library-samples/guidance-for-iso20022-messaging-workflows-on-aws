output "arn" {
  value = aws_mq_broker.this.arn
}

output "id" {
  value = aws_mq_broker.this.id
}

output "instances" {
  value = aws_mq_broker.this.instances
}

output "secret_name" {
  value = aws_secretsmanager_secret.this.name
}

output "region" {
  value = data.aws_region.this.name
}

output "region2" {
  value = (
    data.aws_region.this.name == element(keys(var.backend_bucket), 0)
    ? element(keys(var.backend_bucket), 1) : element(keys(var.backend_bucket), 0)
  )
}

output "custom_domain" {
  value = var.custom_domain
}

output "role_name" {
  value = local.role_name
}

output "rp2_id" {
  value = local.rp2_id
}
