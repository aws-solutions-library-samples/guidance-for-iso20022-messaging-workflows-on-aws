data "terraform_remote_state" "assume" {
  backend = "s3"
  config = {
    skip_region_validation = true

    region = element(keys(var.backend_bucket), 0)
    bucket = var.backend_bucket[element(keys(var.backend_bucket), 0)]
    key    = format(var.backend_pattern, "iam_role_assume")
  }
}

data "terraform_remote_state" "codebuild" {
  backend = "s3"
  config = {
    skip_region_validation = true

    region = element(keys(var.backend_bucket), 0)
    bucket = var.backend_bucket[element(keys(var.backend_bucket), 0)]
    key    = format(var.backend_pattern, "iam_role_codebuild")
  }
}
