locals {
  attributes = [
    {
      name = "id"
      type = "S"
    },
    {
      name = "sk"
      type = "S"
    },
  ]
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
