resource "aws_api_gateway_domain_name" "this" {
  #checkov:skip=CKV_AWS_206:This solution leverages TLS_1_2 security policy (false positive)

  for_each                 = local.domains
  domain_name              = each.value
  regional_certificate_arn = data.aws_acm_certificate.this.arn
  security_policy          = var.q.security_policy

  endpoint_configuration {
    types = var.types
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_base_path_mapping" "healthy" {
  for_each    = local.domains
  domain_name = each.value
  api_id      = data.terraform_remote_state.agw_healthy.outputs.id
  stage_name  = data.terraform_remote_state.agw_healthy.outputs.stage_name
  base_path   = var.q.base_path_healthy
}

resource "aws_api_gateway_base_path_mapping" "unhealthy" {
  for_each    = local.domains
  domain_name = each.value
  api_id      = data.terraform_remote_state.agw_unhealthy.outputs.id
  stage_name  = data.terraform_remote_state.agw_unhealthy.outputs.stage_name
  base_path   = var.q.base_path_unhealthy
}
