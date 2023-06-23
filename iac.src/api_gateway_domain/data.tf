data "terraform_remote_state" "agw_healthy" {
  backend = "s3"
  config = {
    skip_region_validation = true

    region = data.aws_region.this.name
    bucket = var.backend_bucket[data.aws_region.this.name]
    key    = format(var.backend_pattern, "api_gateway_rest")
  }
}

data "terraform_remote_state" "agw_unhealthy" {
  backend = "s3"
  config = {
    skip_region_validation = true

    region = data.aws_region.this.name
    bucket = var.backend_bucket[data.aws_region.this.name]
    key    = format(var.backend_pattern, "api_gateway_mock")
  }
}

data "aws_acm_certificate" "this" {
  domain   = var.custom_domain
  statuses = ["ISSUED"]
}
