q = {
  name                        = "rp2-inbox"
  fifo_queue                  = true
  fifo_throughput_limit       = "perQueue" # "perMessageGroupId"
  deduplication_scope         = "queue" # "messageGroup"
  content_based_deduplication = false
  sqs_managed_sse_enabled     = true
  redrive_permission          = "byQueue"
}
