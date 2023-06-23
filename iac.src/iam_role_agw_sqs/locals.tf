locals {
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess",
    "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
  ]
}
