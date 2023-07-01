locals {
  attributes = [
    {
      name = "id"
      type = "S"
    },
    {
      name = "sk"
      type = "S"
    },
  ]
  global_secondary_indexes = [
    # {
    #   name               = "transaction_id-transaction_status-index"
    #   hash_key           = "transaction_id"
    #   range_key          = "transaction_status"
    #   projection_type    = "INCLUDE"
    #   non_key_attributes = ["id", "created_by", "transaction_code"]
    # },
  ]
  region = (
    data.aws_region.this.name == element(keys(var.backend_bucket), 0)
    ? element(keys(var.backend_bucket), 1) : element(keys(var.backend_bucket), 0)
  )
  region_enabled = (
    data.aws_region.this.name != local.region &&
    !contains(var.r, element(keys(var.backend_bucket), 0)) &&
    !contains(var.r, element(keys(var.backend_bucket), 1))
  )
  replicas = local.region_enabled && data.aws_region.this.name == element(keys(var.backend_bucket), 0) ? [{region_name = local.region}] : []
}
