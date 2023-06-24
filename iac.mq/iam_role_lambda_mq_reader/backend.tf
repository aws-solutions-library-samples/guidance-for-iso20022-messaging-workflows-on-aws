terraform {
  backend "s3" {
    skip_region_validation = true

    key = "terraform/github/rp2/iam_role_lambda_mq_reader/terraform.tfstate"
  }
}
