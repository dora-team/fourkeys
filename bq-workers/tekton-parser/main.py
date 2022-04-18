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

from cloudevents.http import from_http, to_json
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

            event = process_tekton_event(headers, msg)
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


def process_tekton_event(headers, msg):
    data = base64.b64decode(msg["data"]).decode("utf-8").strip()
    cloud_event = from_http(headers, data)

    if "pipelineRun" in cloud_event.data:
        uid = cloud_event.data["pipelineRun"]["metadata"]["uid"]

    if "taskRun" in cloud_event.data:
        uid = cloud_event.data["taskRun"]["metadata"]["uid"]

    event = {
        "event_type": cloud_event["type"],
        "id": uid,  # ID of the taskRun or pipelineRun
        "metadata": to_json(cloud_event).decode(),
        "time_created": cloud_event["time"],
        "signature": cloud_event["id"],  # Unique ID for the event
        "msg_id": msg["message_id"],  # The pubsub message id
        "source": "tekton",
    }

    return event


if __name__ == "__main__":
    PORT = int(os.getenv("PORT")) if os.getenv("PORT") else 8080

    # This is used when running locally. Gunicorn is used to run the
    # application on Cloud Run. See entrypoint in Dockerfile.
    app.run(host="127.0.0.1", port=PORT, debug=True)
