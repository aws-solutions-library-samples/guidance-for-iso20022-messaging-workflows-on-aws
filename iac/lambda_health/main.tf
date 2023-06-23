resource "aws_lambda_function" "this" {
  #checkov:skip=CKV_AWS_50:XRay not needed -- Lambda performs better without tracing enabled
  #checkov:skip=CKV_AWS_117:VPC not supported -- Lambda functions based on images cannot be deployed in VPC
  #checkov:skip=CKV_AWS_173:KMS not needed -- Lambda uses default encryption
  #checkov:skip=CKV_AWS_272:Code sign not supported -- Lambda functions based on images cannot be code signed

  function_name = var.q.function_name
  description   = var.q.description
  role          = data.terraform_remote_state.iam.outputs.arn
  package_type  = var.q.package_type
  architectures = [var.q.architecture]
  image_uri     = format("%s@%s", data.terraform_remote_state.ecr.outputs.repository_url, data.aws_ecr_image.this.id)
  memory_size   = var.q.memory_size
  timeout       = var.q.timeout
  publish       = var.q.publish
  # layers        = local.lambda_layer_arn == null ? null : [local.lambda_layer_arn]

  reserved_concurrent_executions = var.q.reserved

  dead_letter_config {
    target_arn = aws_sqs_queue.this.arn
  }

  environment {
    variables = {
      RP2_LOGGING             = var.q.logging
      RP2_ID                  = data.terraform_remote_state.s3.outputs.rp2_id
      RP2_ACCOUNT             = data.aws_caller_identity.this.account_id
      RP2_REGION              = data.aws_region.this.name
      RP2_API_URL             = format("api-%s", local.domain)
      RP2_AUTH_URL            = format("auth-%s", local.domain)
      RP2_AUTH_CLIENT_ID      = try(local.cognito["client_id"], null)
      RP2_AUTH_CLIENT_SECRET  = try(local.cognito["client_secret"], null)
      RP2_CHECK_REGION        = (data.aws_region.this.name == element(keys(var.backend_bucket), 0)
        ? element(keys(var.backend_bucket), 1) : element(keys(var.backend_bucket), 0))
      # RP2_CHECK_CLIENT_ID     = try(local.cognito2["client_id"], null)
      # RP2_CHECK_CLIENT_SECRET = try(local.cognito2["client_secret"], null)
      RP2_SECRETS             = data.aws_secretsmanager_secret.this.name
      SECRETS_MANAGER_TTL     = var.q.secrets_manager_ttl
    }
  }

  ephemeral_storage {
    size = var.q.storage_size
  }

  tracing_config {
    mode = var.q.tracing_mode
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_sqs_queue" "this" {
  #checkov:skip=CKV_AWS_27:Checkov issue -- cannot read value from default.tfvars

  name                    = var.q.dlq_name
  sqs_managed_sse_enabled = var.q.sqs_managed_sse_enabled
}
