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

import json
import os
import sys

from flask import abort, Flask, request
from google.cloud import pubsub_v1

import sources

PROJECT_NAME = os.environ.get("PROJECT_NAME")

app = Flask(__name__)


@app.route("/", methods=["GET", "POST"])
def index():
    """
    Receives event data from a webhook, checks if the source is authorized,
    checks if the signature is verified, and then sends the data to Pub/Sub.
    """

    # Check if the source is authorized
    source = sources.get_source(request.headers)

    if source not in sources.AUTHORIZED_SOURCES:
        abort(403, f"Source not authorized: {source}")

    auth_source = sources.AUTHORIZED_SOURCES[source]
    signature_sources = {**request.headers, **request.args}
    signature = signature_sources.get(auth_source.signature, None)

    if not signature:
        abort(403, "Signature not found in request headers")

    body = request.data

    # Verify the signature
    verify_signature = auth_source.verification
    if not verify_signature(signature, body):
        abort(403, "Signature does not match expected signature")

    # Remove the Auth header so we do not publish it to Pub/Sub
    pubsub_headers = dict(request.headers)
    if "Authorization" in pubsub_headers:
        del pubsub_headers["Authorization"]

    # Publish to Pub/Sub
    publish_to_pubsub(source, body, pubsub_headers)

    # Flush the stdout to avoid log buffering.
    sys.stdout.flush()
    return "", 204


def publish_to_pubsub(source, msg, headers):
    """
    Publishes the message to Cloud Pub/Sub
    """
    try:
        publisher = pubsub_v1.PublisherClient()
        topic_path = publisher.topic_path(PROJECT_NAME, source)
        print(topic_path)

        # Pub/Sub data must be bytestring, attributes must be strings
        future = publisher.publish(
            topic_path, data=msg, headers=json.dumps(headers)
        )

        exception = future.exception()
        if exception:
            raise Exception(exception)

        print(f"Published message: {future.result()}")

    except Exception as e:
        # Log any exceptions to stackdriver
        entry = dict(severity="WARNING", message=e)
        print(entry)


if __name__ == "__main__":
    PORT = int(os.getenv("PORT")) if os.getenv("PORT") else 8080

    # This is used when running locally. Gunicorn is used to run the
    # application on Cloud Run. See entrypoint in Dockerfile.
    app.run(host="127.0.0.1", port=PORT, debug=True)
