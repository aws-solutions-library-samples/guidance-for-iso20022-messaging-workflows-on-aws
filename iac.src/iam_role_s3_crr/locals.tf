locals {
  region = (
    data.aws_region.this.name == element(keys(var.backend_bucket), 0)
    ? element(keys(var.backend_bucket), 1) : element(keys(var.backend_bucket), 0)
  )
  rp2_id = data.terraform_remote_state.s3.outputs.rp2_id
  source = data.terraform_remote_state.s3.outputs.arn
  target = replace(local.source, data.aws_region.this.name, local.region)
  statements = [
    {
      actions = "s3:GetReplicationConfiguration,s3:ListBucket"
      resources = local.source
    },
    {
      actions = "s3:GetObjectVersion,s3:GetObjectVersionAcl"
      resources = format("%s/*", local.source)
    },
    {
      actions = "s3:ReplicateObject,s3:ReplicateDelete"
      resources = format("%s/*", local.target)
    },
  ]
}
