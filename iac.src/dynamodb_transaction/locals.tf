locals {
  attributes = [
    {
      name = "pk"
      type = "S"
    },
    {
      name = "sk"
      type = "S"
    },
  ]
  rp2_id = data.terraform_remote_state.s3.outputs.rp2_id
  region = (
    data.aws_region.this.name == element(keys(var.backend_bucket), 0)
    ? element(keys(var.backend_bucket), 1) : element(keys(var.backend_bucket), 0)
  )
  replicas_enabled = (
    data.aws_region.this.name != local.region
    && !contains(var.r, element(keys(var.backend_bucket), 0))
    && !contains(var.r, element(keys(var.backend_bucket), 1))
  )
  replicas = (
    local.replicas_enabled
    && data.aws_region.this.name == element(keys(var.backend_bucket), 0)
    ? [ local.region ] : []
  )
}
