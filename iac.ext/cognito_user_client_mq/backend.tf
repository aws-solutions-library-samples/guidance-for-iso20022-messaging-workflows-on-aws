terraform {
  backend "s3" {
    key = "terraform/github/rp2/cognito_user_client_mq/terraform.tfstate"
  }
}
