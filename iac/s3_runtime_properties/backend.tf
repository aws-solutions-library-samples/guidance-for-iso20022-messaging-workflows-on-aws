terraform {
  backend "s3" {
    key = "terraform/github/rp2/s3_runtime_properties/terraform.tfstate"
  }
}
