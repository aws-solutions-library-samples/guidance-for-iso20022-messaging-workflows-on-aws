q = {
  name_queue                  = "rp2-inbox.fifo"
  name_dlq                    = "rp2-inbox-dlq.fifo"
  fifo_queue                  = true
  fifo_throughput_limit       = "perQueue" # "perMessageGroupId"
  content_based_deduplication = false
  deduplication_scope         = "queue" # "messageGroup"
  sqs_managed_sse_enabled     = true
  redrive_permission          = "byQueue"
}
