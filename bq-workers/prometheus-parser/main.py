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
        events = process_prometheus_events(msg)
        if events:
            for event in events:
                print(f" Event which is to be inserted into Big query {event}")
                # [Do not edit below]
                shared.insert_row_into_bigquery(event)

    except Exception as e:
        entry = {
                "severity": "WARNING",
                "msg": "Data not saved to BigQuery",
                "errors": str(e),
                "json_payload": envelope
            }
        print(f"EXCEPTION raised  {json.dumps(entry)}")
    return "", 204


def process_prometheus_events(msg):
    prometheus_events = []
    
    event_map = {
        "firing": "incident.triggered",
        "resolved": "incident.resolved"
    }

    metadata = json.loads(base64.b64decode(msg["data"]).decode("utf-8").strip())

    print(f"Metadata after decoding {metadata}")

    # Unique hash for the event
    signature = shared.create_unique_id(msg)

    for alert in metadata['alerts']:
        alert_status = alert["status"]
        if alert_status not in event_map.keys():
            raise Warning("Unsupported Prometheus event: '%s'" % alert_status)

        time_created = alert['startsAt'] if alert_status == "firing" else alert['endsAt']

        prometheus_events.append(
            {
                "event_type": event_map[alert_status],  # Event type, eg "incident.trigger", "incident.resolved", etc
                "id": alert['fingerprint'],  # Event ID,
                "metadata": json.dumps(alert),  # The body of the msg
                "signature": signature,  # The unique event signature
                "msg_id": msg["message_id"],  # The pubsub message id
                "time_created" : time_created,  # The timestamp of with the event resolved
                "source": "prometheus",  # The name of the source, eg "prometheus"
            }
        )

    print(f"Prometheus alerts to metrics--------> {prometheus_events}")
    return prometheus_events


if __name__ == "__main__":
    PORT = int(os.getenv("PORT")) if os.getenv("PORT") else 8080

    # This is used when running locally. Gunicorn is used to run the
    # application on Cloud Run. See entrypoint in Dockerfile.
    app.run(host="127.0.0.1", port=PORT, debug=True)
