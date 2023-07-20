resource "aws_api_gateway_rest_api" "this" {
  name              = format("%s-%s", var.q.name, local.rp2_id)
  put_rest_api_mode = var.q.mode

  body = templatefile(var.q.file, {
    title         = format("%s-%s", var.q.name, local.rp2_id)
    version       = var.q.version
    region        = data.aws_region.this.name
    api_url       = format("https://api-%s.%s", data.aws_region.this.name, var.custom_domain)
    cognito_key   = format("%s-%s", var.q.secret_name, local.rp2_id)
    cognito_arn   = data.terraform_remote_state.cognito.outputs.arn
    lambda_health = data.terraform_remote_state.lambda_health.outputs.invoke_arn
    lambda_inbox  = data.terraform_remote_state.lambda_inbox.outputs.invoke_arn
    lambda_outbox = data.terraform_remote_state.lambda_outbox.outputs.invoke_arn
    lambda_uuid   = data.terraform_remote_state.lambda_uuid.outputs.invoke_arn
    iam_arn       = data.terraform_remote_state.iam_sqs.outputs.arn
    sqs_arn       = format(var.q.agw_invoke_sqs_arn, data.aws_region.this.name, data.aws_caller_identity.this.account_id, data.terraform_remote_state.sqs.outputs.name)
  })

  endpoint_configuration {
    types = var.types
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.this.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  #checkov:skip=CKV_AWS_73:This solution does not require XRay in production (false positive)
  #checkov:skip=CKV_AWS_120:This solution does not require caching (false positive)
  #checkov:skip=CKV2_AWS_29:This solution does not require WAF yet (false positive)
  #checkov:skip=CKV2_AWS_51:This solution does not require client certs due to OAuth 2.0 implementation (false positive)

  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = var.q.stage

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.this.arn
    format          = var.q.cloudwatch_log_format
  }
}

resource "aws_api_gateway_method_settings" "this" {
  #checkov:skip=CKV_AWS_225:This solution does not require caching (false positive)
  #checkov:skip=CKV_AWS_308:This solution does not require caching (false positive)

  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "ERROR"
  }
}

resource "aws_api_gateway_account" "this" {
  cloudwatch_role_arn = data.terraform_remote_state.iam_logs.outputs.arn
}

resource "aws_cloudwatch_log_group" "this" {
  #checkov:skip=CKV_AWS_158:This solution leverages CloudWatch logs (false positive)

  name              = format(var.q.cloudwatch_group_name, aws_api_gateway_rest_api.this.id, var.q.stage)
  retention_in_days = var.q.retention_in_days
  skip_destroy      = var.q.skip_destroy
}

resource "aws_lambda_permission" "health" {
  principal     = "apigateway.amazonaws.com"
  action        = "lambda:InvokeFunction"
  function_name = data.terraform_remote_state.lambda_health.outputs.function_name
  source_arn    = format("%s/*", aws_api_gateway_rest_api.this.execution_arn)
}

resource "aws_lambda_permission" "inbox" {
  principal     = "apigateway.amazonaws.com"
  action        = "lambda:InvokeFunction"
  function_name = data.terraform_remote_state.lambda_inbox.outputs.function_name
  source_arn    = format("%s/*", aws_api_gateway_rest_api.this.execution_arn)
}

resource "aws_lambda_permission" "outbox" {
  principal     = "apigateway.amazonaws.com"
  action        = "lambda:InvokeFunction"
  function_name = data.terraform_remote_state.lambda_outbox.outputs.function_name
  source_arn    = format("%s/*", aws_api_gateway_rest_api.this.execution_arn)
}

resource "aws_lambda_permission" "uuid" {
  principal     = "apigateway.amazonaws.com"
  action        = "lambda:InvokeFunction"
  function_name = data.terraform_remote_state.lambda_uuid.outputs.function_name
  source_arn    = format("%s/*", aws_api_gateway_rest_api.this.execution_arn)
}

resource "aws_secretsmanager_secret" "this" {
  #checkov:skip=CKV_AWS_149:This solution leverages KMS encryption using AWS managed keys instead of CMKs (false positive)
  #checkov:skip=CKV2_AWS_57:This solution does not require key automatic rotation -- managed by AWS (false positive)

  name        = format("%s-%s-%s", var.q.secret_name, data.aws_region.this.name, local.rp2_id)
  description = var.q.description

  force_overwrite_replica_secret = true

  dynamic "replica" {
    for_each = local.replicas
    content {
      region = replica.value
    }
  }
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({
    RP2_API_ID = aws_api_gateway_rest_api.this.id
  })
}
