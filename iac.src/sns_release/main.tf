resource "aws_sns_topic" "this" {
  name              = var.q.name
  display_name      = var.q.display_name
  kms_master_key_id = var.q.kms_key
  delivery_policy   = file(var.q.delivery_policy)
}

resource "aws_sns_topic_policy" "this" {
  arn    = aws_sns_topic.this.arn
  policy = data.aws_iam_policy_document.this.json
}
