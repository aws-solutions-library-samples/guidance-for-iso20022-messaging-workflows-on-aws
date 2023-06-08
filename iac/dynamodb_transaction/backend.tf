terraform {
  backend "s3" {
    key = "terraform/github/rp2/dynamodb_transaction/terraform.tfstate"
  }
}
