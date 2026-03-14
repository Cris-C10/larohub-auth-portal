resource "aws_cognito_user_pool_client" "larohub_portal" {
  name         = "larohub-portal"
  user_pool_id = aws_cognito_user_pool.larohub.id

  generate_secret = false

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]

  callback_urls = [
    "https://larohub.com/portal/callback",
    "https://www.larohub.com/portal/callback"
  ]
  logout_urls = ["https://larohub.com/"]

  supported_identity_providers = ["COGNITO"]
}
