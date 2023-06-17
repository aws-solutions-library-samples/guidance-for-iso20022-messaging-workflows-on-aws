resource "aws_cognito_user_pool_domain" "this" {
  domain          = format(var.q.domain, data.aws_region.this.name, var.custom_domain)
  certificate_arn = data.aws_acm_certificate.this.arn
  user_pool_id    = data.terraform_remote_state.cognito.outputs.id
}
