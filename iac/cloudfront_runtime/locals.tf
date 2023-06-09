locals {
  logging_config = contains(var.r, data.aws_region.this.name) ? [] : [
    {
      bucket = data.terraform_remote_state.s3.outputs.domain
      prefix = var.q.logging_prefix
    }
  ]
}
