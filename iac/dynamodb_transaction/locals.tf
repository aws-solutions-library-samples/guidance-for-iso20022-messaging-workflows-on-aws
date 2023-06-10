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
  global_table = (
    !contains(var.r, element(keys(var.backend_bucket), 0)) &&
    !contains(var.r, element(keys(var.backend_bucket), 1))
  )
}
