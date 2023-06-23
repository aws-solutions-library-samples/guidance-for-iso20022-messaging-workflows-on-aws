locals {
  rp2_id = data.aws_region.this.name == element(keys(var.backend_bucket), 0) ? random_id.this.hex : data.terraform_remote_state.s3.0.outputs.rp2_id
}
