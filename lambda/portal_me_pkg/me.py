import json
import base64
import urllib.request
import time
import jwt
from jwt import InvalidTokenError

ISSUER = "https://cognito-idp.eu-west-2.amazonaws.com/eu-west-2_MijIHDVyZ"
AUDIENCE = "u2qtjnkdgqppsv2u44latqf76"
JWKS_URL = "https://cognito-idp.eu-west-2.amazonaws.com/eu-west-2_MijIHDVyZ/.well-known/jwks.json"


def _fetch_jwks() -> dict:
    with urllib.request.urlopen(JWKS_URL) as response:
        return json.loads(response.read().decode("utf-8"))


def _b64url_decode(data: str) -> bytes:
    padding = "=" * (-len(data) % 4)
    return base64.urlsafe_b64decode(data + padding)


def _get_cookie(event: dict, name: str) -> str | None:
    cookie_list = event.get("cookies")
    if isinstance(cookie_list, list):
        for c in cookie_list:
            if c.startswith(name + "="):
                return c.split("=", 1)[1]

    headers = event.get("headers") or {}
    cookie_header = headers.get("cookie") or headers.get("Cookie") or ""
    if cookie_header:
        for p in cookie_header.split(";"):
            p = p.strip()
            if p.startswith(name + "="):
                return p.split("=", 1)[1]

    return None


def handler(event, context):
    token = _get_cookie(event, "larohub_id_token")

    if not token:
        return {
            "statusCode": 401,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"authenticated": False, "reason": "missing_cookie"})
        }

    parts = token.split(".")
    if len(parts) != 3:
        return {
            "statusCode": 401,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"authenticated": False, "reason": "invalid_jwt_format"})
        }

    header_b64, payload_b64, signature_b64 = parts

    try:
        payload = json.loads(_b64url_decode(payload_b64).decode("utf-8"))
    except Exception:
        return {
            "statusCode": 401,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"authenticated": False, "reason": "invalid_jwt_payload"})
        }

    if payload.get("iss") != ISSUER:
        return {
            "statusCode": 401,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"authenticated": False, "reason": "invalid_issuer"})
        }

    if payload.get("aud") != AUDIENCE:
        return {
            "statusCode": 401,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"authenticated": False, "reason": "invalid_audience"})
        }

    if payload.get("exp", 0) < int(time.time()):
        return {
            "statusCode": 401,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"authenticated": False, "reason": "token_expired"})
        }

    try:
        header = json.loads(_b64url_decode(header_b64).decode("utf-8"))
    except Exception:
        return {
            "statusCode": 401,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"authenticated": False, "reason": "invalid_jwt_header"})
        }

    kid = header.get("kid")
    if not kid:
        return {
            "statusCode": 401,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"authenticated": False, "reason": "missing_kid"})
        }

    try:
        jwks = _fetch_jwks()
    except Exception:
        return {
            "statusCode": 401,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"authenticated": False, "reason": "jwks_fetch_failed"})
        }

    key = None
    for k in jwks.get("keys", []):
        if k.get("kid") == kid:
            key = k
            break

    if not key:
        return {
            "statusCode": 401,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"authenticated": False, "reason": "jwks_key_not_found"})
        }

    try:
        public_key = jwt.algorithms.RSAAlgorithm.from_jwk(json.dumps(key))
    except Exception:
        return {
            "statusCode": 401,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"authenticated": False, "reason": "public_key_build_failed"})
        }

    try:
        decoded = jwt.decode(
            token,
            public_key,
            algorithms=["RS256"],
            audience=AUDIENCE,
            issuer=ISSUER
        )
    except InvalidTokenError:
        return {
            "statusCode": 401,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"authenticated": False, "reason": "invalid_signature"})
        }

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({
            "authenticated": True,
            "sub": decoded.get("sub"),
            "email": decoded.get("email"),
            "groups": decoded.get("cognito:groups", [])
        })
    }