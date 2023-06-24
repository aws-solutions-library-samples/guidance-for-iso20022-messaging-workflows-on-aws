resource "aws_sqs_queue" "this" {
  #checkov:skip=CKV_AWS_27:This solution leverages KMS encryption using AWS managed keys instead of CMKs (false positive)

  name                    = var.q.name_queue
  sqs_managed_sse_enabled = var.q.sqs_managed_sse_enabled

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_sqs_queue_policy" "this" {
  queue_url = aws_sqs_queue.this.id
  policy    = data.aws_iam_policy_document.this.json
}

resource "aws_sqs_queue" "dlq" {
  #checkov:skip=CKV_AWS_27:This solution leverages KMS encryption using AWS managed keys instead of CMKs (false positive)

  name                    = var.q.name_dlq
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

resource "aws_sns_topic_subscription" "this" {
  topic_arn     = format("arn:aws:sns:%s:%s:%s", data.aws_region.this.name, data.aws_caller_identity.this.account_id, var.q.sns_topic)
  endpoint      = aws_sqs_queue.this.arn
  protocol      = "sqs"
  filter_policy = local.cognito["RP2_AUTH_CLIENT_ID"] != null ? jsonencode({ identity = [local.cognito["RP2_AUTH_CLIENT_ID"]] }) : null
}
