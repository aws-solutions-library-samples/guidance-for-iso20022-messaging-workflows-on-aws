locals {
  domain = format("%s.%s", data.aws_region.this.name, data.terraform_remote_state.s3.outputs.custom_domain)
  rp2_id = data.terraform_remote_state.s3.outputs.rp2_id
  region = (
    data.aws_region.this.name == element(keys(var.backend_bucket), 0)
    ? element(keys(var.backend_bucket), 1) : element(keys(var.backend_bucket), 0)
  )
}
