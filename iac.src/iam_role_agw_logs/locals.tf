locals {
  rp2_id = data.terraform_remote_state.s3.outputs.rp2_id
  policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
  ]
}
