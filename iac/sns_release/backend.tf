terraform {
  backend "s3" {
    key = "terraform/github/rp2/sns_release/terraform.tfstate"
  }
}
