resource "aws_lambda_function" "this" {
  #checkov:skip=CKV_AWS_50:This solution does not require XRay in production (false positive)
  #checkov:skip=CKV_AWS_117:This solution does not support VPC due to container based images (false positive)
  #checkov:skip=CKV_AWS_173:This solution leverages KMS encryption using AWS managed keys instead of CMKs (false positive)
  #checkov:skip=CKV_AWS_272:This solution does not support code signing due to container based images (false positive)

  function_name = var.q.function_name
  description   = var.q.description
  role          = data.terraform_remote_state.iam.outputs.arn
  package_type  = var.q.package_type
  architectures = [var.q.architecture]
  image_uri     = format("%s@%s", data.terraform_remote_state.ecr.outputs.repository_url, data.aws_ecr_image.this.id)
  memory_size   = var.q.memory_size
  timeout       = var.q.timeout
  publish       = var.q.publish

  reserved_concurrent_executions = var.q.reserved

  dead_letter_config {
    target_arn = aws_sqs_queue.this.arn
  }

  environment {
    variables = {
      RP2_LOGGING       = var.q.logging
      RP2_ID            = local.rp2_id
      RP2_ACCOUNT       = data.aws_caller_identity.this.account_id
      RP2_REGION        = data.aws_region.this.name
      RP2_API_URL       = format("api-%s", local.domain)
      RP2_AUTH_URL      = format("auth-%s", local.domain)
      RP2_CHECK_REGION  = local.region
      RP2_SECRETS_REST  = local.rest_api
      RP2_SECRETS_MOCK  = local.mock_api
      RP2_SECRETS       = data.aws_secretsmanager_secret.this.name

      SECRETS_MANAGER_TTL = var.q.secrets_manager_ttl
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
  #checkov:skip=CKV_AWS_27:This solution leverages KMS encryption using AWS managed keys instead of CMKs (false positive)

  name                    = var.q.dlq_name
  sqs_managed_sse_enabled = var.q.sqs_managed_sse_enabled
}
