q = {
  name         = "rp2-transaction"
  hash_key     = "pk"
  range_key    = "sk"
  billing_mode = "PAY_PER_REQUEST"

  stream_enabled         = true
  stream_view_type       = "NEW_AND_OLD_IMAGES"
  point_in_time_recovery = true
  encryption_enabled     = true
  ttl_enabled            = false
  ttl_attribute_name     = "ttl_time"
}

# Not Supported Regions for DynamoDB Global Tables
# https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GlobalTables.html#GlobalTablesReplicate

r = [
  "ap-east-1",
  "ap-south-2",
  "ap-southeast-3",
  "ap-southeast-4",
  "eu-north-1",
  "eu-south-1",
  "eu-south-2",
  "eu-central-2",
  "me-south-1",
  "me-central-1"
]
