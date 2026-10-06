import json
import os
import secrets
import string
import time
from urllib.parse import urlparse

import boto3
from botocore.exceptions import ClientError

TABLE = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])
ALPHABET = string.ascii_letters + string.digits
CODE_LENGTH = 7
TTL_DAYS = 30
MAX_ATTEMPTS = 3


def _response(status, body):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }


def handler(event, context):
    try:
        long_url = json.loads(event.get("body") or "{}").get("url", "")
    except json.JSONDecodeError:
        return _response(400, {"error": "invalid JSON"})

    parsed = urlparse(long_url)
    if parsed.scheme not in ("http", "https") or not parsed.netloc:
        return _response(400, {"error": "url must be http(s)"})

    expires_at = int(time.time()) + TTL_DAYS * 86400

    for _ in range(MAX_ATTEMPTS):
        code = "".join(secrets.choice(ALPHABET) for _ in range(CODE_LENGTH))
        try:
            TABLE.put_item(
                Item={"short_code": code, "long_url": long_url, "expires_at": expires_at},
                ConditionExpression="attribute_not_exists(short_code)",
            )
        except ClientError as e:
            if e.response["Error"]["Code"] == "ConditionalCheckFailedException":
                continue
            raise
        ctx = event.get("requestContext", {})
        short_url = f"https://{ctx.get('domainName')}/{ctx.get('stage')}/{code}"
        return _response(201, {"short_code": code, "short_url": short_url})

    return _response(503, {"error": "could not allocate code, retry"})