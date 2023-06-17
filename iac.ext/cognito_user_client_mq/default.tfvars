q = {
  name          = "rp2-mq"
  description   = "RP2 MQ"
  cognito_name  = "rp2-cognito-users"
  access_token  = "minutes"
  id_token      = "minutes"
  refresh_token = "days"
  secret_name   = "rp2-client-mq"

  access_token_validity = 480
  id_token_validity     = 480

  allowed_oauth_flows_user_pool_client = true
}

allowed_oauth_flows          = ["client_credentials"]
allowed_oauth_scopes         = ["rp2/read", "rp2/write"]
supported_identity_providers = ["COGNITO"]

explicit_auth_flows = [
  "ALLOW_ADMIN_USER_PASSWORD_AUTH",
  "ALLOW_CUSTOM_AUTH",
  "ALLOW_REFRESH_TOKEN_AUTH",
  "ALLOW_USER_PASSWORD_AUTH",
  "ALLOW_USER_SRP_AUTH"
]
