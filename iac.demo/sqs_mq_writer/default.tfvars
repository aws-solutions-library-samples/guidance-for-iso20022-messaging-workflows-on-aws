q = {
  name_queue              = "rp2-mq-writer"
  name_dlq                = "rp2-mq-writer-dlq"
  redrive_permission      = "byQueue"
  sqs_managed_sse_enabled = true
  sns_topic               = "rp2-release"
}
