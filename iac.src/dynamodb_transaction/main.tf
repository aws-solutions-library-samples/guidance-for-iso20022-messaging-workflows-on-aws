resource "aws_dynamodb_table" "this" {
  #checkov:skip=CKV_AWS_28:This solution leverages DynamoDB point in time recovery / backup (false positive)
  #checkov:skip=CKV_AWS_119:This solution leverages KMS encryption using AWS managed keys instead of CMKs (false positive)
  #checkov:skip=CKV2_AWS_16:This solution does not leverages DynamoDB auto-scaling capabilities (false positive)

  count        = (local.replicas_enabled && data.aws_region.this.name == element(keys(var.backend_bucket), 0)) || !local.replicas_enabled ? 1 : 0
  name         = format("%s-%s", var.q.name, local.rp2_id)
  hash_key     = var.q.hash_key
  range_key    = var.q.range_key
  billing_mode = var.q.billing_mode

  stream_enabled   = var.q.stream_enabled
  stream_view_type = var.q.stream_view_type

  dynamic "attribute" {
    for_each = local.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "replica" {
    for_each = local.replicas
    content {
      region_name = replica.value
    }
  }

  point_in_time_recovery {
    enabled = var.q.point_in_time_recovery
  }

  server_side_encryption {
    enabled = var.q.encryption_enabled
  }

  # ttl {
  #   enabled        = var.q.ttl_enabled
  #   attribute_name = var.q.ttl_attribute_name
  # }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [replica, read_capacity, write_capacity]
  }
}
