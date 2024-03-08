q = {
  name    = "rp2-agw-healthy"
  mode    = "overwrite"
  file    = "swagger.json.tftpl"
  version = "2023-01-30T23:30:40Z"
  stage   = "v1"
  format  = "$context.identity.sourceIp $context.identity.caller $context.identity.user [$context.requestTime] \"$context.httpMethod $context.resourcePath $context.protocol\" $context.status $context.responseLength $context.requestId"

  secret_name = "rp2-rest-api"
  description = "RP2 REST API"

  agw_invoke_sqs_arn   = "arn:aws:apigateway:%s:sqs:path/%s/%s"
  cw_group_name_prefix = "API-Gateway-Execution-Logs"
  retention_in_days    = 5
  skip_destroy         = true
}

types = ["REGIONAL"]
