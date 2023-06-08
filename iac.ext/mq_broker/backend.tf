terraform {
  backend "s3" {
    key = "terraform/github/rp2/mq_broker/terraform.tfstate"
  }
}
