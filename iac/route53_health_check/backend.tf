terraform {
  backend "s3" {
    skip_region_validation = true

    key = "terraform/github/rp2/route53_health_check/terraform.tfstate"
  }
}
