q = {
  name                       = "rp2-cognito-users"
  mfa_enabled                = true
  mfa_configuration          = "OPTIONAL"
  case_sensitive             = false
  sms_authentication_message = "Your verification code is {####}. "

  recovery_mechanism_name     = "verified_email"
  recovery_mechanism_priority = 1

  allow_admin_create_user_only = true
  email_sending_account        = "COGNITO_DEFAULT"

  invite_email_message = "Your username is {username} and temporary password is {####}. "
  invite_email_subject = "Your temporary password"
  invite_sms_message   = "Your username is {username} and temporary password is {####}. "

  minimum_length                   = 8
  require_lowercase                = true
  require_numbers                  = true
  require_symbols                  = true
  require_uppercase                = true
  temporary_password_validity_days = 7

  schema                   = "email"
  required                 = true
  mutable                  = true
  attribute_data_type      = "String"
  developer_only_attribute = false
  min_length               = "0"
  max_length               = "2048"

  default_email_option       = "CONFIRM_WITH_CODE"
  verification_email_message = "Your verification code is {####}. "
  verification_email_subject = "Your verification code"
  verification_sms_message   = "Your verification code is {####}. "

  resource_server_name       = "rp2"
  resource_server_identifier = "rp2"
}

attributes = ["email"]
