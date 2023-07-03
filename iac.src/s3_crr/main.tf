resource "aws_s3_bucket_replication_configuration" "this" {
  bucket = data.terraform_remote_state.s3.outputs.id
  role   = data.terraform_remote_state.iam.outputs.arn

  dynamioc "rule" {
    for_each = local.rules
    content {
      id     = each.value
      status = var.q.status

      filter {
        prefix = each.value
      }

      destination {
        bucket        = local.target
        storage_class = var.q.storage_class
      }
    }
  }
}
