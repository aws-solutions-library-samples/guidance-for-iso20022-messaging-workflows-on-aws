terraform {
  backend "s3" {
    skip_region_validation = true

    key = "terraform/github/rp2/mq_broker/terraform.tfstate"
  }
}
