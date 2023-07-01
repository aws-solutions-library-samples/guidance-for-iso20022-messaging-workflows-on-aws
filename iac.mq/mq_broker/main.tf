resource "aws_mq_broker" "this" {
  #checkov:skip=CKV_AWS_197:This solution does not support audit logging due to RabbitMQ engine (false positive)
  #checkov:skip=CKV_AWS_207:This solution leverages minor updates by default (false positive)
  #checkov:skip=CKV_AWS_209:This solution leverages KMS encryption using AWS managed keys instead of CMKs (false positive)

  broker_name                = var.q.broker_name
  engine_type                = var.q.engine_type
  engine_version             = var.q.engine_version
  host_instance_type         = var.q.host_instance_type
  publicly_accessible        = var.q.publicly_accessible
  auto_minor_version_upgrade = var.q.auto_minor_version_upgrade
  apply_immediately          = var.q.apply_immediately

  logs {
    general = true
  }

  user {
    username = var.q.username
    password = random_password.this.result
  }
}

resource "random_password" "this" {
  length  = 16
  lower   = true
  upper   = true
  numeric = true
  special = true

  override_special = "!@#$&_+"

  lifecycle {
    ignore_changes = [length, lower, upper, numeric, special]
  }
}

resource "aws_secretsmanager_secret" "this" {
  #checkov:skip=CKV_AWS_149:This solution leverages KMS encryption using AWS managed keys instead of CMKs (false positive)
  #checkov:skip=CKV2_AWS_57:This solution does not require key automatic rotation -- managed by AWS (false positive)

  name        = format("%s-%s-%s", var.q.secret_name, data.aws_region.this.name, local.rp2_id)
  description = var.q.description

  force_overwrite_replica_secret = true

  dynamic "replica" {
    for_each = local.replicas
    content {
      region = replica.value.region
    }
  }
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({
    RP2_RMQ_HOST = replace(aws_mq_broker.this.instances.0.console_url, "https://", "")
    RP2_RMQ_PORT = element(split(":", aws_mq_broker.this.instances.0.endpoints.0), 2)
    RP2_RMQ_USER = var.q.username
    RP2_RMQ_PASS = random_password.this.result
  })
}
