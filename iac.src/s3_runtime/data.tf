data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    skip_region_validation = true

    region = data.aws_region.this.name
    bucket = var.backend_bucket[data.aws_region.this.name]
    key    = format(var.backend_pattern, "iam_role_assume")
  }
}

data "terraform_remote_state" "s3" {
  count = (
    data.aws_region.this.name == element(keys(var.backend_bucket), 1)
    && data.aws_region.this.name != local.region ? 1 : 0
  )
  backend = "s3"
  config = {
    skip_region_validation = true

    region = element(keys(var.backend_bucket), 0)
    bucket = var.backend_bucket[element(keys(var.backend_bucket), 0)]
    key    = format(var.backend_pattern, "s3_runtime")
  }
}
