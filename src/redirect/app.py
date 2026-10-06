import json
import os
import time

import boto3

TABLE = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])


def _not_found():
    return {
        "statusCode": 404,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"error": "not found"}),
    }


def handler(event, context):
    code = (event.get("pathParameters") or {}).get("code")
    if not code:
        return _not_found()

    item = TABLE.get_item(Key={"short_code": code}).get("Item")
    if not item or int(item.get("expires_at", 0)) < int(time.time()):
        return _not_found()

    return {
        "statusCode": 301,
        "headers": {"Location": item["long_url"]},
        "body": "",
    }