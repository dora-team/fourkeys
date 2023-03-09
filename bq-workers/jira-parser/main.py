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
    
    if "message" not in envelope:
        raise Exception("Not a valid Pub/Sub Message")
    msg = envelope["message"]
    attr = msg["attributes"]
    
    headers = None

    # Header Event info
    if "headers" in attr:
        headers = json.loads(attr["headers"])
    if "attributes" not in msg:
        raise Exception("Missing pubsub attributes")
    
    try:
        event = process_jira_event(headers, msg)
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
    
def process_jira_event(headers, msg):
    
    event_type = msg["webhookEvent"]
    signature = headers["X-Hub-Signature"]
    
    if event_type=="jira:issue_created" or event_type=="jira:issue_updated":
        time_created = msg["issue"]["fields"]["updated"]
        e_id = "jira/"+msg["issue"]["key"]
    
    return {
        "event_type": event_type,
        "id": e_id,
        "metadata": json.dumps(msg),
        "time_created": time_created,
        "signature": signature,
        "msg_id": msg["message_id"],
        "source": "jira"
    }

if __name__ == "__main__":
    PORT = int(os.getenv("PORT")) if os.getenv("PORT") else 8080

    # This is used when running locally. Gunicorn is used to run the
    # application on Cloud Run. See entrypoint in Dockerfile.
    app.run(host="127.0.0.1", port=PORT, debug=True)
