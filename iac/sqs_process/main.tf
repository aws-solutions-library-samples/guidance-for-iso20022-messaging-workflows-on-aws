resource "aws_sqs_queue" "this" {
  #checkov:skip=CKV_AWS_27:Checkov issue -- cannot read value from default.tfvars

  name                        = var.q.name_queue
  fifo_queue                  = var.q.fifo_queue
  fifo_throughput_limit       = var.q.fifo_throughput_limit
  content_based_deduplication = var.q.content_based_deduplication
  deduplication_scope         = var.q.deduplication_scope
  sqs_managed_sse_enabled     = var.q.sqs_managed_sse_enabled

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_sqs_queue_policy" "this" {
  queue_url = aws_sqs_queue.this.id
  policy    = data.aws_iam_policy_document.this.json
}

resource "aws_sqs_queue" "dlq" {
  #checkov:skip=CKV_AWS_27:Checkov issue -- cannot read value from default.tfvars

  name                    = var.q.name_dlq
  fifo_queue              = var.q.fifo_queue
  sqs_managed_sse_enabled = var.q.sqs_managed_sse_enabled

  redrive_allow_policy = jsonencode({
    redrivePermission = var.q.redrive_permission
    sourceQueueArns   = [aws_sqs_queue.this.arn]
  })
}

resource "aws_sqs_queue_policy" "dlq" {
  queue_url = aws_sqs_queue.dlq.id
  policy    = data.aws_iam_policy_document.dlq.json
}
