locals {
  rp2_id = (
    data.aws_region.this.name == element(keys(var.backend_bucket), 0)
    ? random_id.this.hex : data.terraform_remote_state.s3.0.outputs.rp2_id
  )
  environment_variables = [
    {
      name  = "AWS_DEFAULT_REGION"
      type  = "PLAINTEXT"
      value = data.aws_region.this.name
    },
    {
      name  = "AWS_REGION"
      type  = "PLAINTEXT"
      value = data.aws_region.this.name
    },
    {
      name  = "RP2_REGION"
      type  = "PLAINTEXT"
      value = data.aws_region.this.name
    },
    {
      name  = "RP2_DOMAIN"
      type  = "PLAINTEXT"
      value = var.custom_domain
    },
    {
      name  = "RP2_BACKEND"
      type  = "PLAINTEXT"
      value = format("{%s}", join(",", [for key, value in var.backend_bucket : "\"${key}\"=\"${value}\""]))
    },
    {
      name  = "RP2_ID"
      type  = "PLAINTEXT"
      value = local.rp2_id
    },
  ]
}
