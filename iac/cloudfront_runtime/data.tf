data "terraform_remote_state" "s3" {
  backend = "s3"
  config = {
    region = data.aws_region.this.name
    bucket = var.backend_bucket[data.aws_region.this.name]
    key    = format(var.backend_pattern, "s3_runtime")
  }
}
