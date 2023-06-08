q = {
  name         = "rp2-transaction"
  hash_key     = "id"
  range_key    = "transaction_id"
  billing_mode = "PAY_PER_REQUEST"

  stream_enabled         = true
  stream_view_type       = "NEW_AND_OLD_IMAGES"
  point_in_time_recovery = true
  encryption_enabled     = true
  ttl_enabled            = false
  ttl_attribute_name     = "ttl_time"
  replica_not_supported  = true
}
