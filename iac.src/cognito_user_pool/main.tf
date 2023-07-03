resource "aws_cognito_user_pool" "this" {
  name                       = var.q.name
  alias_attributes           = var.attributes
  auto_verified_attributes   = var.attributes
  mfa_configuration          = var.q.mfa_configuration
  sms_authentication_message = var.q.sms_authentication_message

  account_recovery_setting {
    recovery_mechanism {
      name     = var.q.recovery_mechanism_name
      priority = var.q.recovery_mechanism_priority
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = var.q.allow_admin_create_user_only
    invite_message_template {
      email_message = var.q.invite_email_message
      email_subject = var.q.invite_email_subject
      sms_message   = var.q.invite_sms_message
    }
  }

  email_configuration {
    email_sending_account = var.q.email_sending_account
  }

  password_policy {
    minimum_length                   = var.q.minimum_length
    require_lowercase                = var.q.require_lowercase
    require_numbers                  = var.q.require_numbers
    require_symbols                  = var.q.require_symbols
    require_uppercase                = var.q.require_uppercase
    temporary_password_validity_days = var.q.temporary_password_validity_days
  }

  schema {
    name                     = var.q.schema
    required                 = var.q.required
    mutable                  = var.q.mutable
    attribute_data_type      = var.q.attribute_data_type
    developer_only_attribute = var.q.developer_only_attribute
    string_attribute_constraints {
      min_length = var.q.min_length
      max_length = var.q.max_length
    }
  }

  sms_configuration {
    external_id    = data.terraform_remote_state.iam.outputs.external_id
    sns_caller_arn = data.terraform_remote_state.iam.outputs.arn
    sns_region     = data.aws_region.this.name
  }

  software_token_mfa_configuration {
    enabled = var.q.mfa_enabled
  }

  username_configuration {
    case_sensitive = var.q.case_sensitive
  }

  verification_message_template {
    default_email_option = var.q.default_email_option
    email_message        = var.q.verification_email_message
    email_subject        = var.q.verification_email_subject
    sms_message          = var.q.verification_sms_message
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cognito_resource_server" "this" {
  name         = var.q.resource_server_name
  identifier   = var.q.resource_server_identifier
  user_pool_id = aws_cognito_user_pool.this.id

  dynamic "scope" {
    for_each = local.scopes
    content {
      scope_name        = each.value.name
      scope_description = each.value.description
    }
  }
}
