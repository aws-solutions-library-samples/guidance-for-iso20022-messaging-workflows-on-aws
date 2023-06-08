terraform {
  backend "s3" {
    key = "terraform/github/rp2/sqs_inbox/terraform.tfstate"
  }
}
