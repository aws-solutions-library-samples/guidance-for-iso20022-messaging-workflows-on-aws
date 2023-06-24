locals {
  queues = [
    "inbox.pacs.002",
    "inbox.pacs.008",
    "outbox.pacs.002",
    "outbox.pacs.008",
  ]
  secrets = jsondecode(data.aws_secretsmanager_secret_version.this.secret_string)
}
