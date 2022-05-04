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

        # Header Event info
        if "headers" in attr:
            headers = json.loads(attr["headers"])

            # Process Github Events
            if "X-Github-Event" in headers:
                event = process_github_event(headers, msg)

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


def process_github_event(headers, msg):
    event_type = headers["X-Github-Event"]
    signature = headers["X-Hub-Signature"]
    source = "github"

    if "Mock" in headers:
        source += "mock"

    types = {"push", "pull_request", "pull_request_review",
             "pull_request_review_comment", "issues",
             "issue_comment", "check_run", "check_suite", "status",
             "deployment_status", "release"}

    if event_type not in types:
        raise Exception("Unsupported GitHub event: '%s'" % event_type)

    metadata = json.loads(base64.b64decode(msg["data"]).decode("utf-8").strip())

    if event_type == "push":
        time_created = metadata["head_commit"]["timestamp"]
        e_id = metadata["head_commit"]["id"]

    if event_type == "pull_request":
        time_created = metadata["pull_request"]["updated_at"]
        e_id = metadata["repository"]["name"] + "/" + str(metadata["number"])

    if event_type == "pull_request_review":
        time_created = metadata["review"]["submitted_at"]
        e_id = metadata["review"]["id"]

    if event_type == "pull_request_review_comment":
        time_created = metadata["comment"]["updated_at"]
        e_id = metadata["comment"]["id"]

    if event_type == "issues":
        time_created = metadata["issue"]["updated_at"]
        e_id = metadata["repository"]["name"] + "/" + str(metadata["issue"]["number"])

    if event_type == "issue_comment":
        time_created = metadata["comment"]["updated_at"]
        e_id = metadata["comment"]["id"]

    if event_type == "check_run":
        time_created = (metadata["check_run"]["completed_at"] or
                        metadata["check_run"]["started_at"])
        e_id = metadata["check_run"]["id"]

    if event_type == "check_suite":
        time_created = (metadata["check_suite"]["updated_at"] or
                        metadata["check_suite"]["created_at"])
        e_id = metadata["check_suite"]["id"]

    if event_type == "deployment_status":
        time_created = metadata["deployment_status"]["updated_at"]
        e_id = metadata["deployment_status"]["id"]

    if event_type == "status":
        time_created = metadata["updated_at"]
        e_id = metadata["id"]

    if event_type == "release":
        time_created = (metadata["release"]["published_at"] or
                        metadata["release"]["created_at"])
        e_id = metadata["release"]["id"]

    github_event = {
        "event_type": event_type,
        "id": e_id,
        "metadata": json.dumps(metadata),
        "time_created": time_created,
        "signature": signature,
        "msg_id": msg["message_id"],
        "source": source,
    }

    return github_event


if __name__ == "__main__":
    PORT = int(os.getenv("PORT")) if os.getenv("PORT") else 8080

    # This is used when running locally. Gunicorn is used to run the
    # application on Cloud Run. See entrypoint in Dockerfile.
    app.run(host="127.0.0.1", port=PORT, debug=True)
