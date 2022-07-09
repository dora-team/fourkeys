# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import base64
import os
import json

import shared

from flask import Flask, request

app = Flask(__name__)


@app.route("/", methods=["POST"])
def index():
    """
    Receives messages from a push subscription from Pub/Sub.
    Parses the message, and inserts it into BigQuery.
    """
    event = None
    # Check request for JSON
    if not request.is_json:
        raise Exception("Expecting JSON payload")
    envelope = request.get_json()

    # Check that message is a valid pub/sub message
    if "message" not in envelope:
        raise Exception("Not a valid Pub/Sub Message")
    msg = envelope["message"]

    if "attributes" not in msg:
        raise Exception("Missing pubsub attributes")

    try:
        attr = msg["attributes"]

        if "headers" in attr:
            headers = json.loads(attr["headers"])

            if "Sentry-Hook-Resource" in headers:
                event = process_sentry_event(headers, msg)

        shared.insert_row_into_bigquery(event)

    except Exception as e:
        entry = {
            "severity": "WARNING",
            "msg": "Data not saved to BigQuery",
            "errors": str(e),
            "json_payload": envelope
        }
        print(json.dumps(entry))

    return "", 204


def process_sentry_event(headers, msg):
    event_type = headers["Sentry-Hook-Resource"]
    metadata = json.loads(base64.b64decode(msg["data"]).decode("utf-8").strip())
    types = {"issue"}

    if event_type not in types:
        raise Exception("Unsupported Sentry event: '%s'" % event_type)

    return {
        "event_type": event_type,
        "id": metadata["data"]["issue"]["id"],
        "metadata": json.dumps(metadata),
        "time_created": headers["Sentry-Hook-Timestamp"],
        "signature": headers["Sentry-Hook-Signature"],
        "msg_id": msg["message_id"],
        "source": "sentry",
    }


if __name__ == "__main__":
    PORT = int(os.getenv("PORT")) if os.getenv("PORT") else 8080

    # This is used when running locally. Gunicorn is used to run the
    # application on Cloud Run. See entrypoint in Dockerfile.
    app.run(host="127.0.0.1", port=PORT, debug=True)
