locals {
  region = (
    data.aws_region.this.name == element(keys(var.backend_bucket), 0)
    ? element(keys(var.backend_bucket), 1) : element(keys(var.backend_bucket), 0)
  )
  target = replace(data.terraform_remote_state.s3.outputs.arn, data.aws_region.this.name, local.region)
  rules = ["inbox", "outbox"]
}
