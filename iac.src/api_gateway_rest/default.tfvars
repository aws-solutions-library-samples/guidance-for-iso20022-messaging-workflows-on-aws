q = {
  name    = "rp2-agw-healthy"
  mode    = "overwrite"
  file    = "swagger.json"
  version = "2023-01-30T23:30:40Z"
  stage   = "v1"

  retention_in_days = 5
  skip_destroy      = true

  agw_invoke_sqs_arn    = "arn:aws:apigateway:%s:sqs:path/%s/rp2-inbox.fifo"
  cloudwatch_group_name = "API-Gateway-Execution-Logs_%s/%s"
  cloudwatch_log_format = "$context.identity.sourceIp $context.identity.caller $context.identity.user [$context.requestTime] \"$context.httpMethod $context.resourcePath $context.protocol\" $context.status $context.responseLength $context.requestId"
}

types = ["REGIONAL"]
