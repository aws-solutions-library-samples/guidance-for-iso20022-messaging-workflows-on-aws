terraform {
  backend "s3" {
    skip_region_validation = true

    key = "terraform/github/rp2/cognito_user_client_mq/terraform.tfstate"
  }
}
