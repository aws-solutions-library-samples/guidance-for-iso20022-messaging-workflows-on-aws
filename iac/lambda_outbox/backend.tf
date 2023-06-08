terraform {
  backend "s3" {
    key = "terraform/github/rp2/lambda_outbox/terraform.tfstate"
  }
}
