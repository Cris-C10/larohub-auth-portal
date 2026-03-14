def lambda_handler(event, context):

    return {
        "statusCode": 302,
        "headers": {
            "Location": "https://larohub.com/",
            "Set-Cookie": "larohub_id_token=deleted; Max-Age=0; Path=/; HttpOnly; Secure; SameSite=Lax"
        }
    }