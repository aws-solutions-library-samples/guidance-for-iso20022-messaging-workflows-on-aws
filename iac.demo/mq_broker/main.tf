resource "aws_mq_broker" "this" {
  #checkov:skip=CKV_AWS_197:Not supported -- audit logging not supported by RabbitMQ
  #checkov:skip=CKV_AWS_207:Checkov issue -- cannot read value from default.tfvars
  #checkov:skip=CKV_AWS_209:Checkov issue -- cannot read value from default.tfvars

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
  #checkov:skip=CKV_AWS_149:Checkov issue -- cannot read value from default.tfvars
  #checkov:skip=CKV2_AWS_57:Automatic rotation not needed -- cannot keep in sync with Cognito

  name        = format("%s-%s-%s", var.q.secret_name, data.aws_region.this.name, local.rp2_id)
  description = var.q.description

  force_overwrite_replica_secret = true

  replica {
    region = data.aws_region.this.name == element(keys(var.backend_bucket), 0) ? element(keys(var.backend_bucket), 1) : element(keys(var.backend_bucket), 0)
  }
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({
    rmq_host = replace(aws_mq_broker.this.instances.0.console_url, "https://", "")
    rmq_user = var.q.username
    rmq_pass = random_password.this.result
  })
}
