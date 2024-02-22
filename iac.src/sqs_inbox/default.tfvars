q = {
  name                        = "rp2-inbox"
  fifo_queue                  = false
  fifo_throughput_limit       = null # "perQueue" # "perMessageGroupId"
  content_based_deduplication = false
  deduplication_scope         = null # "queue" # "messageGroup"
  sqs_managed_sse_enabled     = true
  redrive_permission          = "byQueue"
}
