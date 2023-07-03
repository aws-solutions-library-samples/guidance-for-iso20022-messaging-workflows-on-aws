resource "aws_dynamodb_table" "this" {
  #checkov:skip=CKV_AWS_28:This solution leverages DynamoDB point in time recovery / backup (false positive)
  #checkov:skip=CKV_AWS_119:This solution leverages KMS encryption using AWS managed keys instead of CMKs (false positive)
  #checkov:skip=CKV2_AWS_16:This solution does not leverages DynamoDB auto-scaling capabilities (false positive)

  count        = (local.replicas_enabled && data.aws_region.this.name == element(keys(var.backend_bucket), 0)) || !local.replicas_enabled ? 1 : 0
  name         = var.q.name
  hash_key     = var.q.hash_key
  range_key    = var.q.range_key
  billing_mode = var.q.billing_mode

  stream_enabled   = var.q.stream_enabled
  stream_view_type = var.q.stream_view_type

  dynamic "attribute" {
    for_each = local.attributes
    content {
      name = each.value.name
      type = each.value.type
    }
  }

  dynamic "global_secondary_index" {
    for_each = local.global_secondary_indexes
    content {
      name               = each.value.name
      hash_key           = each.value.hash_key
      range_key          = each.value.range_key
      projection_type    = each.value.projection_type
      non_key_attributes = each.value.non_key_attributes
    }
  }

  dynamic "replica" {
    for_each = local.replicas
    content {
      region_name = each.value.region_name
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
