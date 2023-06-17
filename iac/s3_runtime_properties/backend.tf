terraform {
  backend "s3" {
    skip_region_validation = true

    key = "terraform/github/rp2/s3_runtime_properties/terraform.tfstate"
  }
}
