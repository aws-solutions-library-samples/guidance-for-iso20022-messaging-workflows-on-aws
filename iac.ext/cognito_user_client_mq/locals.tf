locals {
  rp2_id = data.terraform_remote_state.mq.outputs.rp2_id
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
}
