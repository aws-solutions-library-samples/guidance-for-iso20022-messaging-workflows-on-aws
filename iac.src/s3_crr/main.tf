resource "aws_s3_bucket_replication_configuration" "this" {
  bucket = data.terraform_remote_state.s3.outputs.id
  role   = data.terraform_remote_state.iam.outputs.arn

  dynamic "rule" {
    for_each = local.rules
    content {
      id     = rule.value
      status = var.q.status

      filter {
        prefix = rule.value
      }

      destination {
        bucket        = local.target
        storage_class = var.q.storage_class
      }
    }
  }
}
