terraform {
  backend "s3" {
    key = "terraform/github/rp2/cognito_user_pool/terraform.tfstate"
  }
}
