terraform {
  backend "s3" {
    key = "terraform/github/rp2/cloudfront_runtime/terraform.tfstate"
  }
}
