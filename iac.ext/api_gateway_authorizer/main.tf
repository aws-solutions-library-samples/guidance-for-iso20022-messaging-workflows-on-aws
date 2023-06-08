resource "aws_api_gateway_authorizer" "this" {
  name            = var.q.name
  type            = var.q.type
  identity_source = var.q.identity_source
  rest_api_id     = data.terraform_remote_state.agw.outputs.id
  provider_arns   = [data.terraform_remote_state.cognito.outputs.arn]

  lifecycle {
    create_before_destroy = true
  }
}
