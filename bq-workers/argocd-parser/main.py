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
    if not request.is_json:
        raise Exception("Expecting JSON payload")
    envelope = request.get_json()
    print(f"envelope recieved: {envelope}")

    # Check that data has been posted
    if not envelope:
        raise Exception("Expecting JSON payload")
    # Check that message is a valid pub/sub message
    if "message" not in envelope:
        raise Exception("Not a valid Pub/Sub Message")
    msg = envelope["message"]

    if "attributes" not in msg:
        raise Exception("Missing pubsub attributes")

    try:
        event = process_argocd_event(msg)

        # [Do not edit below]
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


def process_argocd_event(msg):
    metadata = json.loads(base64.b64decode(msg["data"]).decode("utf-8").strip())

    # Unique hash for the event
    signature = shared.create_unique_id(msg)

    argocd_event = {
        "event_type": "deployment",  # Event type, eg "push", "pull_reqest", etc
        "id": metadata["id"],  # Object ID, eg pull request ID
        "metadata": json.dumps(metadata),  # The body of the msg
        "time_created": metadata["time"],  # The timestamp of with the event
        "signature": signature,  # The unique event signature
        "msg_id": msg["message_id"],  # The pubsub message id
        "source": "argocd",  # The name of the source, eg "github"
    }

    print(argocd_event)
    return argocd_event


if __name__ == "__main__":
    PORT = int(os.getenv("PORT")) if os.getenv("PORT") else 8080

    # This is used when running locally. Gunicorn is used to run the
    # application on Cloud Run. See entrypoint in Dockerfile.
    app.run(host="127.0.0.1", port=PORT, debug=True)
