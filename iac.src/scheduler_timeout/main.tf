resource "aws_scheduler_schedule" "this" {
  #checkov:skip=CKV_AWS_297:This solution leverages KMS encryption using AWS managed keys instead of CMKs (false positive)

  name       = data.terraform_remote_state.lambda.outputs.function_name
  group_name = var.q.group_name
  state      = var.q.state

  schedule_expression = var.q.schedule_expression

  flexible_time_window {
    mode = var.q.mode
  }

  target {
    arn      = data.terraform_remote_state.lambda.outputs.arn
    role_arn = data.terraform_remote_state.iam.outputs.arn

    dead_letter_config {
      arn = aws_sqs_queue.this.arn
    }
  }
}

resource "aws_sqs_queue" "this" {
  #checkov:skip=CKV_AWS_27:This solution leverages KMS encryption using AWS managed keys instead of CMKs (false positive)

  name                    = replace(data.terraform_remote_state.lambda.outputs.function_name, local.rp2_id, local.dlq)
  sqs_managed_sse_enabled = var.q.sqs_managed_sse_enabled
}
