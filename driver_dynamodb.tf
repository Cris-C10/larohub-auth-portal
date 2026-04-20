# ------------------------------------------------------------------------------------
# DynamoDB — device registry for LARO DRIVER
# One row per device (Android ID). Stores first-seen timestamp (trial clock),
# per-device kill flag, and licence flag. Read/written by the driver_api Lambda.
# ------------------------------------------------------------------------------------
resource "aws_dynamodb_table" "larohub_devices" {
  name         = "larohub-devices"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "device_id"

  attribute {
    name = "device_id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }
}

output "larohub_devices_table_name" {
  value = aws_dynamodb_table.larohub_devices.name
}

output "larohub_devices_table_arn" {
  value = aws_dynamodb_table.larohub_devices.arn
}