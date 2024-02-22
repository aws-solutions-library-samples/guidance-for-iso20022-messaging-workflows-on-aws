q = {
  name                        = "rp2-health"
  fifo_queue                  = false
  fifo_throughput_limit       = "perQueue" # "perMessageGroupId"
  content_based_deduplication = false
  deduplication_scope         = "queue" # "messageGroup"
  sqs_managed_sse_enabled     = true
  redrive_permission          = "byQueue"
}
