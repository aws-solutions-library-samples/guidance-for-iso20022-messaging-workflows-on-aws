locals {
  region = (
    data.aws_region.this.name == element(keys(var.backend_bucket), 0)
    ? element(keys(var.backend_bucket), 1) : element(keys(var.backend_bucket), 0)
  )
  rp2_id = (var.rp2_id == null ? (
    data.aws_region.this.name == element(keys(var.backend_bucket), 0)
    ? random_id.this.hex : data.terraform_remote_state.s3.0.outputs.rp2_id
  ) : var.rp2_id)
  role_name = data.terraform_remote_state.iam.outputs.name
}
