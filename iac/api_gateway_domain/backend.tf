terraform {
  backend "s3" {
    skip_region_validation = true

    key = "terraform/github/rp2/api_gateway_domain/terraform.tfstate"
  }
}
