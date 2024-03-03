q = {
  name    = "rp2-agw-unhealthy"
  mode    = "overwrite"
  file    = "swagger.json.tftpl"
  version = "2023-01-30T23:30:40Z"
  stage   = "v0"
  format  = "$context.identity.sourceIp $context.identity.caller $context.identity.user [$context.requestTime] \"$context.httpMethod $context.resourcePath $context.protocol\" $context.status $context.responseLength $context.requestId"

  secret_name = "rp2-mock-api"
  description = "RP2 MOCK API"

  cw_group_name_prefix = "API-Gateway-Execution-Logs"
  retention_in_days    = 5
  skip_destroy         = true
}

types = ["REGIONAL"]
