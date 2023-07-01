locals {
  rp2_id = data.terraform_remote_state.s3.outputs.rp2_id
  domain = format("%s.%s", data.aws_region.this.name, data.terraform_remote_state.s3.outputs.custom_domain)
}
