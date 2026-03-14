import json
import os
import urllib.parse
import urllib.request


def _token_exchange(code: str) -> dict:
    domain = os.environ["COGNITO_DOMAIN"]          # larohub-auth.auth.eu-west-2.amazoncognito.com
    client_id = os.environ["COGNITO_CLIENT_ID"]    # u2qt...
    redirect_uri = os.environ["REDIRECT_URI"]      # https://larohub.com/portal/callback

    token_url = f"https://{domain}/oauth2/token"

    body = urllib.parse.urlencode({
        "grant_type": "authorization_code",
        "client_id": client_id,
        "code": code,
        "redirect_uri": redirect_uri,
    }).encode("utf-8")

    req = urllib.request.Request(
        token_url,
        data=body,
        method="POST",
        headers={"Content-Type": "application/x-www-form-urlencoded"},
    )

    with urllib.request.urlopen(req, timeout=5) as resp:
        return json.loads(resp.read().decode("utf-8"))


def handler(event, context):
    qs = event.get("queryStringParameters") or {}
    code = qs.get("code")
    if not code:
        return {
            "statusCode": 302,
            "headers": {
                "location": "https://larohub.com/dashboard.html?auth=missing_code",
                "cache-control": "no-store",
            },
            "body": ""
        }

    try:
        tokens = _token_exchange(code)
    except Exception:
        return {
            "statusCode": 302,
            "headers": {
                "location": "https://larohub.com/dashboard.html?auth=token_exchange_failed",
                "cache-control": "no-store",
            },
            "body": ""
        }

    id_token = tokens.get("id_token", "")

    cookie = (
        f"larohub_id_token={id_token}; "
        f"Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=3600"
    )

    return {
        "statusCode": 302,
        "headers": {
            "location": "https://larohub.com/dashboard.html?auth=ok",
            "set-cookie": cookie,
            "cache-control": "no-store",
        },
        "body": ""
    }