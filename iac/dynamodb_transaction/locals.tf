locals {
  attributes = [
    {
      name = "id"
      type = "S"
    },
    {
      name = "transaction_id"
      type = "S"
    },
    # {
    #   name = "transaction_status"
    #   type = "S"
    # },
    # {
    #   name = "request_region"
    #   type = "S"
    # },
  ]
  gsi = [
    # {
    #   name               = "transaction_id-transaction_status-index"
    #   hash_key           = "transaction_id"
    #   range_key          = "transaction_status"
    #   projection_type    = "INCLUDE"
    #   non_key_attributes = ["id", "created_by", "transaction_code"]
    # },
    # {
    #   name               = "transaction_status-request_region-index"
    #   hash_key           = "transaction_status"
    #   range_key          = "request_region"
    #   projection_type    = "INCLUDE"
    #   non_key_attributes = ["id", "created_by", "transaction_id"]
    # },
  ]
}
