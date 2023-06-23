locals {
  domain = format("%s.%s", data.aws_region.this.name, data.terraform_remote_state.mq.outputs.custom_domain)
}
