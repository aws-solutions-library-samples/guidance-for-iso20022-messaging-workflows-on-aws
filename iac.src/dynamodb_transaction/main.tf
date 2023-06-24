resource "aws_dynamodb_table" "this" {
  #checkov:skip=CKV_AWS_119:This solution leverages KMS encryption using AWS managed keys instead of CMKs
  #checkov:skip=CKV2_AWS_16:This solution does not leverages DynamoDB auto-scaling capabilities

  count        = (local.global_table && data.aws_region.this.name == element(keys(var.backend_bucket), 0)) || !local.global_table ? 1 : 0
  name         = var.q.name
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

  dynamic "global_secondary_index" {
    for_each = local.global_secondary_indexes
    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      range_key          = global_secondary_index.value.range_key
      projection_type    = global_secondary_index.value.projection_type
      non_key_attributes = global_secondary_index.value.non_key_attributes
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

resource "aws_dynamodb_table_replica" "this" {
  #checkov:skip=CKV_AWS_271:This solution leverages KMS encryption using AWS managed keys instead of CMKs
  #checkov:skip=CKV2_AWS_16:This solution does not leverages DynamoDB auto-scaling capabilities

  provider = aws.glob
  count    = local.global_table && data.aws_region.this.name == element(keys(var.backend_bucket), 0) ? 1 : 0

  global_table_arn       = aws_dynamodb_table.this.0.arn
  point_in_time_recovery = var.q.point_in_time_recovery

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [replica, read_capacity, write_capacity]
  }
}

provider "aws" {
  alias  = "glob"
  region = element(keys(var.backend_bucket), 1)

  skip_region_validation = true
}
