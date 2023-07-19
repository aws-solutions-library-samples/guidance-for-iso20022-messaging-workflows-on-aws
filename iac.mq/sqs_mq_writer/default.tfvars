q = {
  name                    = "rp2-mq-writer"
  redrive_permission      = "byQueue"
  sqs_managed_sse_enabled = true
  sns_topic               = "rp2-release"
}
