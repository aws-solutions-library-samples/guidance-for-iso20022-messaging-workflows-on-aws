terraform {
  backend "s3" {
    key = "terraform/github/rp2/sqs_mq_writer/terraform.tfstate"
  }
}
