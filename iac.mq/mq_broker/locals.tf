locals {
  bucket_arn = data.terraform_remote_state.s3.outputs.arn
  role_name = data.terraform_remote_state.iam.outputs.name
  rp2_id = data.terraform_remote_state.s3.outputs.rp2_id
  region = (
    data.aws_region.this.name == element(keys(var.backend_bucket), 0)
    ? element(keys(var.backend_bucket), 1) : element(keys(var.backend_bucket), 0)
  )
  replicas = local.region == data.aws_region.this.name ? [] : [ local.region ]
}
