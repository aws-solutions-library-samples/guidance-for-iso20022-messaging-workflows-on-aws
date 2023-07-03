locals {
  attributes = [
    "address",
    "birthdate",
    "email",
    "family_name",
    "gender",
    "given_name",
    "locale",
    "middle_name",
    "name",
    "nickname",
    "phone_number",
    "picture",
    "preferred_username",
    "profile",
    "updated_at",
    "website",
    "zoneinfo",
    "email_verified",
    "phone_number_verified",
  ]
  rp2_id = data.terraform_remote_state.s3.outputs.rp2_id
  region = (
    data.aws_region.this.name == element(keys(var.backend_bucket), 0)
    ? element(keys(var.backend_bucket), 1) : element(keys(var.backend_bucket), 0)
  )
  replicas = local.region == data.aws_region.this.name ? [] : [ local.region ]
}
