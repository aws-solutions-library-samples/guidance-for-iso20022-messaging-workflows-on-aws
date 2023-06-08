terraform {
  backend "s3" {
    key = "terraform/github/rp2/iam_role_agw_logs/terraform.tfstate"
  }
}
