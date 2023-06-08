terraform {
  backend "s3" {
    key = "terraform/github/rp2/ecr_mq_writer/terraform.tfstate"
  }
}
