# ------------------------------------------------------------------------------------
# LARO DRIVER API — Lambda + IAM role
# Single Lambda serves two routes (/licence, /notify) via API Gateway.
# Python 3.12, packaged from lambda/driver_api.py.
# ------------------------------------------------------------------------------------

# ── Package the Python source into a zip ────────────────────────────────────────────
data "archive_file" "driver_api_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/driver_api.py"
  output_path = "${path.module}/lambda/driver_api.zip"
}

# ── IAM execution role ──────────────────────────────────────────────────────────────
resource "aws_iam_role" "driver_api_lambda_role" {
  name = "larohub-driver-api-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# ── CloudWatch logs (basic Lambda execution) ────────────────────────────────────────
resource "aws_iam_role_policy_attachment" "driver_api_basic_logs" {
  role       = aws_iam_role.driver_api_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ── DynamoDB read/write on larohub-devices only ─────────────────────────────────────
resource "aws_iam_role_policy" "driver_api_dynamodb" {
  name = "larohub-driver-api-dynamodb"
  role = aws_iam_role.driver_api_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
      ]
      Resource = aws_dynamodb_table.larohub_devices.arn
    }]
  })
}

# ── SES send email (scoped to our verified sender identity) ─────────────────────────
resource "aws_iam_role_policy" "driver_api_ses" {
  name = "larohub-driver-api-ses"
  role = aws_iam_role.driver_api_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ses:SendEmail",
        "ses:SendRawEmail",
      ]
      Resource = [
        "arn:aws:ses:eu-west-2:944625998404:identity/larohub.com",
        "arn:aws:ses:eu-west-2:944625998404:identity/contact@larohub.com",
      ]
    }]
  })
}

# ── Lambda function ─────────────────────────────────────────────────────────────────
resource "aws_lambda_function" "driver_api" {
  function_name    = "larohub-driver-api"
  role             = aws_iam_role.driver_api_lambda_role.arn
  runtime          = "python3.12"
  handler          = "driver_api.lambda_handler"
  filename         = data.archive_file.driver_api_zip.output_path
  source_code_hash = data.archive_file.driver_api_zip.output_base64sha256
  timeout          = 10
  memory_size      = 256

  environment {
    variables = {
      DEVICES_TABLE_NAME = aws_dynamodb_table.larohub_devices.name
      OPERATOR_EMAIL     = "contact@larohub.com"
      SES_SENDER         = "contact@larohub.com"
      KILL_SWITCH_GLOBAL = "false"
      TRIAL_DAYS         = "7"
    }
  }
}

# ── Outputs ─────────────────────────────────────────────────────────────────────────
output "driver_api_lambda_name" {
  value = aws_lambda_function.driver_api.function_name
}

output "driver_api_lambda_arn" {
  value = aws_lambda_function.driver_api.arn
}
