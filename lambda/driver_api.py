"""
LARO Driver API — two routes on one Lambda:
  POST /licence  → device licence check (kill switch, trial window)
  POST /notify   → operator email notification via SES

Invoked by API Gateway HTTP API (payload format 2.0).
No authentication at the HTTP layer — device_id is the identifier.
"""

import json
import os
import time
import boto3
from botocore.exceptions import ClientError

# ------------------------------------------------------------------------------------
# Environment (set by Terraform)
# ------------------------------------------------------------------------------------
DEVICES_TABLE_NAME = os.environ["DEVICES_TABLE_NAME"]
OPERATOR_EMAIL     = os.environ["OPERATOR_EMAIL"]
SES_SENDER         = os.environ["SES_SENDER"]
KILL_SWITCH_GLOBAL = os.environ.get("KILL_SWITCH_GLOBAL", "false").lower() == "true"
TRIAL_DAYS         = int(os.environ.get("TRIAL_DAYS", "7"))

# ------------------------------------------------------------------------------------
# AWS clients (reused across warm invocations)
# ------------------------------------------------------------------------------------
dynamodb = boto3.resource("dynamodb")
devices_table = dynamodb.Table(DEVICES_TABLE_NAME)
ses = boto3.client("ses")

# ------------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------------
def _response(status, body):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }

def _now_ms():
    return int(time.time() * 1000)

# ------------------------------------------------------------------------------------
# /licence — device licence check
# ------------------------------------------------------------------------------------
def handle_licence(body):
    device_id = (body or {}).get("device_id", "").strip()
    if not device_id:
        return _response(400, {"error": "device_id required"})

    # Global kill switch — env var, flip in Lambda config to kill everyone
    if KILL_SWITCH_GLOBAL:
        return _response(200, {"killed": True, "licensed": False})

    # Look up or create the device row
    now = _now_ms()
    try:
        item = devices_table.get_item(Key={"device_id": device_id}).get("Item")
    except ClientError as e:
        print(f"DynamoDB get_item error: {e}")
        # Fail open on infra errors — driver must not be blocked by our bugs
        return _response(200, {"killed": False, "licensed": True})

    if item is None:
        # First contact — create row with first_seen = now
        try:
            devices_table.put_item(Item={
                "device_id": device_id,
                "first_seen": now,
                "killed": False,
                "licensed": True,
            })
        except ClientError as e:
            print(f"DynamoDB put_item error: {e}")
            return _response(200, {"killed": False, "licensed": True})
        return _response(200, {"killed": False, "licensed": True})

    # Existing device — evaluate
    if item.get("killed", False):
        return _response(200, {"killed": True, "licensed": False})

    first_seen = int(item.get("first_seen", now))
    age_days = (now - first_seen) / (1000 * 60 * 60 * 24)
    licensed = age_days < TRIAL_DAYS

    return _response(200, {"killed": False, "licensed": licensed})

# ------------------------------------------------------------------------------------
# /notify — email operator
# ------------------------------------------------------------------------------------
def handle_notify(body):
    b = body or {}
    device_id   = b.get("device_id", "unknown")
    driver      = b.get("driver", "unknown")
    reg         = b.get("reg", "unknown")
    shift_id    = b.get("shift_id", "unknown")
    fault_count = b.get("fault_count", 0)

    subject = f"LARO Driver — shift {shift_id} — {reg} — {fault_count} fault(s)"
    text = (
        f"A daily vehicle check has been filed.\n\n"
        f"Driver: {driver}\n"
        f"Tractor reg: {reg}\n"
        f"Shift ID: {shift_id}\n"
        f"Fault count: {fault_count}\n"
        f"Device ID: {device_id}\n"
    )

    try:
        ses.send_email(
            Source=SES_SENDER,
            Destination={"ToAddresses": [OPERATOR_EMAIL]},
            Message={
                "Subject": {"Data": subject},
                "Body": {"Text": {"Data": text}},
            },
        )
        return _response(200, {"sent": True})
    except ClientError as e:
        print(f"SES send_email error: {e}")
        # Fire-and-forget from the app's perspective — still return 200 so the
        # driver flow never blocks on email. Failure is logged for ops review.
        return _response(200, {"sent": False})

# ------------------------------------------------------------------------------------
# Main handler — routes on path
# ------------------------------------------------------------------------------------
def lambda_handler(event, context):
    raw_path = event.get("rawPath", "")
    method = event.get("requestContext", {}).get("http", {}).get("method", "")

    # Parse body (API Gateway sends it as a string)
    body = {}
    raw_body = event.get("body")
    if raw_body:
        try:
            body = json.loads(raw_body)
        except json.JSONDecodeError:
            return _response(400, {"error": "invalid JSON body"})

    if method != "POST":
        return _response(405, {"error": "method not allowed"})

    if raw_path.endswith("/licence"):
        return handle_licence(body)
    if raw_path.endswith("/notify"):
        return handle_notify(body)

    return _response(404, {"error": "route not found", "path": raw_path})