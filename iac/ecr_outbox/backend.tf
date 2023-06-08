terraform {
  backend "s3" {
    key = "terraform/github/rp2/ecr_outbox/terraform.tfstate"
  }
}
