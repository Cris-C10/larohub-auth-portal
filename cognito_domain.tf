resource "aws_cognito_user_pool_domain" "larohub" {
  domain       = "larohub-auth"
  user_pool_id = aws_cognito_user_pool.larohub.id
}