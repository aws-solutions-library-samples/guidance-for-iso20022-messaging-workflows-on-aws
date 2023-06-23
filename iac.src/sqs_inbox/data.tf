data "aws_iam_policy_document" "this" {
  statement {
    effect    = "Allow"
    actions   = ["sqs:*"]
    resources = [aws_sqs_queue.this.arn]

    principals {
      type        = "AWS"
      identifiers = [format("arn:aws:iam::%s:root", data.aws_caller_identity.this.account_id)]
    }
  }
}

data "aws_iam_policy_document" "dlq" {
  statement {
    effect    = "Allow"
    actions   = ["sqs:*"]
    resources = [aws_sqs_queue.dlq.arn]

    principals {
      type        = "AWS"
      identifiers = [format("arn:aws:iam::%s:root", data.aws_caller_identity.this.account_id)]
    }
  }
}
