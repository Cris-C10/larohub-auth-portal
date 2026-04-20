############################################
# API Gateway v2 (HTTP API) → LARO Driver Lambda
############################################

resource "aws_apigatewayv2_api" "driver_api" {
  name          = "larohub-driver-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "driver_api_stage" {
  api_id      = aws_apigatewayv2_api.driver_api.id
  name        = "$default"
  auto_deploy = true
}

############################################
# Integrations
############################################

resource "aws_apigatewayv2_integration" "driver_licence_integration" {
  api_id                 = aws_apigatewayv2_api.driver_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.driver_api.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "driver_notify_integration" {
  api_id                 = aws_apigatewayv2_api.driver_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.driver_api.arn
  payload_format_version = "2.0"
}

############################################
# Routes
############################################

resource "aws_apigatewayv2_route" "driver_licence_route" {
  api_id    = aws_apigatewayv2_api.driver_api.id
  route_key = "POST /licence"
  target    = "integrations/${aws_apigatewayv2_integration.driver_licence_integration.id}"
}

resource "aws_apigatewayv2_route" "driver_notify_route" {
  api_id    = aws_apigatewayv2_api.driver_api.id
  route_key = "POST /notify"
  target    = "integrations/${aws_apigatewayv2_integration.driver_notify_integration.id}"
}

############################################
# Allow API Gateway to invoke Lambda
############################################

resource "aws_lambda_permission" "allow_apigw_invoke_driver_api" {
  statement_id  = "AllowExecutionFromAPIGatewayDriverApi"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.driver_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.driver_api.execution_arn}/*/*"
}

############################################
# Outputs
############################################

output "driver_api_endpoint" {
  value = aws_apigatewayv2_api.driver_api.api_endpoint
}
