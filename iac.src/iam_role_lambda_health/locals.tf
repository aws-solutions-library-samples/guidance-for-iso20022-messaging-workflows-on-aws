locals {
  rp2_id = data.terraform_remote_state.s3.outputs.rp2_id
  statements = [
    {
      actions = "cloudwatch:*"
      resources = format(
        "arn:aws:cloudwatch:*:%s:insight-rule/DynamoDBContributorInsights*",
        data.aws_caller_identity.this.account_id
      )
    },
    {
      actions = "logs:*,tag:GetResources"
      resources = format(
        "arn:aws:logs:*:%s:log-group:/aws/lambda/rp2-*,arn:aws:logs:*:%s:log-group:API-Gateway-*",
        data.aws_caller_identity.this.account_id, data.aws_caller_identity.this.account_id
      )
    },
    {
      actions = "dynamodb:*,application-autoscaling:*,tag:GetResources"
      resources = format(
        "arn:aws:dynamodb:*:%s:table/rp2-*,arn:aws:dynamodb::%s:global-table/rp2-*",
        data.aws_caller_identity.this.account_id, data.aws_caller_identity.this.account_id
      )
    },
    {
      actions = "kms:DescribeKey,kms:ListAliases,kms:Decrypt"
      resources = format(
        "arn:aws:kms:*:%s:key/*",
        data.aws_caller_identity.this.account_id
      )
    },
    {
      actions = "secretsmanager:GetSecretValue"
      resources = format(
        "arn:aws:secretsmanager:*:%s:secret:rp2-*",
        data.aws_caller_identity.this.account_id
      )
    },
    {
      actions = "lambda:InvokeFunction,tag:GetResources"
      resources = format(
        "arn:aws:lambda:*:%s:function:rp2-*",
        data.aws_caller_identity.this.account_id
      )
    },
    {
      actions = "s3:*,s3-object-lambda:*,tag:GetResources"
      resources = format(
        "%s,%s/*",
        data.terraform_remote_state.s3.outputs.arn,
        data.terraform_remote_state.s3.outputs.arn
      )
    },
    {
      actions = "sns:*,tag:GetResources"
      resources = format(
        "arn:aws:sns:*:%s:rp2-*",
        data.aws_caller_identity.this.account_id
      )
    },
    {
      actions = "sqs:*,tag:GetResources"
      resources = format(
        "arn:aws:sqs:*:%s:rp2-*",
        data.aws_caller_identity.this.account_id
      )
    },
  ]
}
