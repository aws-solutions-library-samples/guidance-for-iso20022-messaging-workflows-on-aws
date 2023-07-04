q = {
  group_name = "default"
  state      = "DISABLED"
  mode       = "OFF"

  schedule_expression     = "rate(1 minutes)"
  sqs_managed_sse_enabled = true
}
