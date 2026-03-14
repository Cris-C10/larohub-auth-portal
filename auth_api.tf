############################################
# API Gateway v2 (HTTP API) → Lambda
############################################

resource "aws_apigatewayv2_api" "portal_auth_api" {
  name          = "larohub-portal-auth-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "portal_callback_integration" {
  api_id                 = aws_apigatewayv2_api.portal_auth_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.portal_callback.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "portal_callback_route" {
  api_id    = aws_apigatewayv2_api.portal_auth_api.id
  route_key = "GET /portal/callback"
  target    = "integrations/${aws_apigatewayv2_integration.portal_callback_integration.id}"
}

resource "aws_apigatewayv2_integration" "portal_me_integration" {
  api_id                 = aws_apigatewayv2_api.portal_auth_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.portal_me.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "portal_me_route" {
  api_id    = aws_apigatewayv2_api.portal_auth_api.id
  route_key = "GET /portal/me"
  target    = "integrations/${aws_apigatewayv2_integration.portal_me_integration.id}"
}

resource "aws_apigatewayv2_stage" "portal_auth_stage" {
  api_id      = aws_apigatewayv2_api.portal_auth_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "portal_logout_integration" {
  api_id                 = aws_apigatewayv2_api.portal_auth_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.portal_logout.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "portal_logout_route" {
  api_id    = aws_apigatewayv2_api.portal_auth_api.id
  route_key = "GET /portal/logout"
  target    = "integrations/${aws_apigatewayv2_integration.portal_logout_integration.id}"
}

############################################
# Allow API Gateway to invoke Lambda
############################################

resource "aws_lambda_permission" "allow_apigw_invoke_portal_me" {
  statement_id  = "AllowExecutionFromAPIGatewayPortalMe"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.portal_me.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.portal_auth_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_apigw_invoke_portal_callback" {
  statement_id  = "AllowExecutionFromAPIGatewayPortalCallback"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.portal_callback.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.portal_auth_api.execution_arn}/*/*"
}

output "portal_auth_api_endpoint" {
  value = aws_apigatewayv2_api.portal_auth_api.api_endpoint
}

resource "aws_lambda_permission" "allow_apigw_invoke_portal_logout" {
  statement_id  = "AllowExecutionFromAPIGatewayPortalLogout"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.portal_logout.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.portal_auth_api.execution_arn}/*/*"
}