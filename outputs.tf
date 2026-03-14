output "cognito_domain" {
  value = aws_cognito_user_pool_domain.larohub.domain
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.larohub.id
}

output "cognito_app_client_id" {
  value = aws_cognito_user_pool_client.larohub_portal.id
}

output "cognito_hosted_ui_base_url" {
  value = "https://${aws_cognito_user_pool_domain.larohub.domain}.auth.eu-west-2.amazoncognito.com"
}