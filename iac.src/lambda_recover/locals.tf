locals {
  domain = format("%s.%s", data.aws_region.this.name, data.terraform_remote_state.s3.outputs.custom_domain)
  rp2_id = data.terraform_remote_state.s3.outputs.rp2_id
  region = (
    data.aws_region.this.name == element(keys(var.backend_bucket), 0)
    ? element(keys(var.backend_bucket), 1) : element(keys(var.backend_bucket), 0)
  )
  rest_api = (
    local.region == data.aws_region.this.name ? null : replace(
      data.terraform_remote_state.apigw_rest.outputs.secret_name,
      data.aws_region.this.name, local.region
    )
  )
  mock_api = (
    local.region == data.aws_region.this.name ? null : replace(
      data.terraform_remote_state.apigw_mock.outputs.secret_name,
      data.aws_region.this.name, local.region
    )
  )
}
