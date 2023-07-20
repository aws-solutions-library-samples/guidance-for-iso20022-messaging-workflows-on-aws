output "arn" {
  value = aws_sqs_queue.this.arn
}

output "id" {
  value = aws_sqs_queue.this.id
}

output "url" {
  value = aws_sqs_queue.this.url
}

output "name" {
  value = aws_sqs_queue.this.name
}

output "subscription_arn" {
  value = aws_sns_topic_subscription.this.arn
}

output "subscription_id" {
  value = aws_sns_topic_subscription.this.id
}

output "subscription_protocol" {
  value = aws_sns_topic_subscription.this.protocol
}

output "subscription_endpoint" {
  value = aws_sns_topic_subscription.this.endpoint
}
