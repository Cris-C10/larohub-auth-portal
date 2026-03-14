############################################
# IAM Role for Lambda
############################################

resource "aws_iam_role" "portal_callback_lambda_role" {
  name = "larohub-portal-callback-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "portal_callback_basic_logs" {
  role       = aws_iam_role.portal_callback_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

############################################
# Zip the Lambda source
############################################

data "archive_file" "portal_callback_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/callback.py"
  output_path = "${path.module}/lambda/callback.zip"
}

############################################
# Lambda Function
############################################

resource "aws_lambda_function" "portal_callback" {
  function_name = "larohub-portal-callback"
  role          = aws_iam_role.portal_callback_lambda_role.arn
  handler       = "callback.handler"
  runtime       = "python3.12"

  filename         = data.archive_file.portal_callback_zip.output_path
  source_code_hash = data.archive_file.portal_callback_zip.output_base64sha256

  timeout     = 5
  memory_size = 128

  environment {
    variables = {
      COGNITO_DOMAIN    = "${aws_cognito_user_pool_domain.larohub.domain}.auth.eu-west-2.amazoncognito.com"
      COGNITO_CLIENT_ID = aws_cognito_user_pool_client.larohub_portal.id
      REDIRECT_URI      = "https://larohub.com/portal/callback"
    }
  }
}

resource "aws_lambda_function" "portal_me" {
  function_name = "larohub-portal-me"
  role          = aws_iam_role.portal_callback_lambda_role.arn
  handler       = "me.handler"
  runtime       = "python3.12"

  filename         = "${path.module}/portal_me.zip"
  source_code_hash = filebase64sha256("${path.module}/portal_me.zip")

  timeout     = 5
  memory_size = 128
}

resource "aws_lambda_function" "portal_logout" {
  function_name = "larohub-portal-logout"

  role    = aws_iam_role.portal_callback_lambda_role.arn
  handler = "logout.lambda_handler"
  runtime = "python3.12"

  filename         = "${path.module}/lambda/logout.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/logout.zip")

  timeout = 5
}