locals {
  rp2_id = data.terraform_remote_state.s3.outputs.rp2_id
  region = (
    data.aws_region.this.name == element(keys(var.backend_bucket), 0)
    ? element(keys(var.backend_bucket), 1) : element(keys(var.backend_bucket), 0)
  )
  replicas = [
    {
      region = (local.region == data.aws_region.this.name ? null : local.region)
    }
  ]
}
