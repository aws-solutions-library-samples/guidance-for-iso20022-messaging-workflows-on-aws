terraform {
  backend "s3" {
    key = "terraform/github/rp2/api_gateway_domain/terraform.tfstate"
  }
}
