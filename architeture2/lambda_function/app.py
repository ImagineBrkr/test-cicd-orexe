import json
import requests
import os

def lambda_handler(event, context):
    name = "World"
    if "DEFAULT_NAME" in os.environ:
        name = os.environ["DEFAULT_NAME"]

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "hello "+name,
        }),
    }