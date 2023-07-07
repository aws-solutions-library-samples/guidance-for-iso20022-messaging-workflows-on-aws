terraform {
  backend "s3" {
    skip_region_validation = true

    key = "terraform/github/rp2/waf_web_acl/terraform.tfstate"
  }
}
