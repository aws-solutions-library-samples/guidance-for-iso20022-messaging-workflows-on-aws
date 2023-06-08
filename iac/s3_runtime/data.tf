data "terraform_remote_state" "s3" {
  count   = data.aws_region.this.name == element(keys(var.backend_bucket), 1) ? 1 : 0
  backend = "s3"
  config = {
    region = element(keys(var.backend_bucket), 0)
    bucket = var.backend_bucket[element(keys(var.backend_bucket), 0)]
    key    = format(var.backend_pattern, "s3_runtime")
  }
}
