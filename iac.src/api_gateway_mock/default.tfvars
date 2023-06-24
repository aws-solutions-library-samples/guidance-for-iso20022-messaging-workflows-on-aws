q = {
  name    = "rp2-agw-unhealthy"
  mode    = "overwrite"
  file    = "swagger.json.tftpl"
  version = "2023-01-30T23:30:40Z"
  stage   = "v0"

  retention_in_days = 5
  skip_destroy      = true

  cloudwatch_group_name = "API-Gateway-Execution-Logs_%s/%s"
  cloudwatch_log_format = "$context.identity.sourceIp $context.identity.caller $context.identity.user [$context.requestTime] \"$context.httpMethod $context.resourcePath $context.protocol\" $context.status $context.responseLength $context.requestId"
}

types = ["REGIONAL"]
