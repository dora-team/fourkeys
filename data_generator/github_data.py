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


import datetime
import hmac
import json
import random
import os
import secrets
import time

from hashlib import sha1
from urllib.request import Request, urlopen


def make_changes(num_changes):
    changes = []
    # One week ago
    max_time = time.time() - 604800
    head_commit = None

    for x in range(num_changes):
        change_id = secrets.token_hex(20)
        unix_timestamp = time.time() - random.randrange(0, 604800)
        change = {
            "id": change_id,
            "timestamp": datetime.datetime.fromtimestamp(unix_timestamp),
        }

        if unix_timestamp > max_time:
            max_time = unix_timestamp
            head_commit = change

        changes.append(change)

    event = {"head_commit": head_commit, "commits": changes}
    return event


def make_issue(root_cause):
    event = {
        "issue": {
            "created_at": root_cause["timestamp"],
            "updated_at": datetime.datetime.now(),
            "closed_at": datetime.datetime.now(),
            "number": random.randrange(0, 1000),
            "labels": [{"name": "Incident"}],
            "body": "root cause: %s" % root_cause["id"],
        }
    }
    return event


def send_mock_github_events(event_type, data):
    webhook_url = os.environ.get("WEBHOOK")
    data = json.dumps(data, default=str).encode()
    secret = os.environ.get("SECRET").encode()
    signature = hmac.new(secret, data, sha1)

    request = Request(webhook_url, data)
    request.add_header("X-Github-Event", event_type)
    request.add_header("X-Hub-Signature", "sha1=" + signature.hexdigest())
    request.add_header("User-Agent", "GitHub-Hookshot/mock")
    request.add_header("Content-Type", "application/json")
    request.add_header("Mock", True)

    response = urlopen(request)

    if response.getcode() == 204:
        return 1
    else:
        return 0


def create_deploy_event(change):
    deployment = {
        "deployment": {
            "updated_at": change["timestamp"],
            "id": secrets.token_hex(20),
            "sha": change["id"],
        }
    }
    return deployment


def generate_data():
    num_success = 0
    changes = make_changes(2)

    # Send individual changes data
    for c in changes["commits"]:
        curr_change = {"head_commit": c, "commits": [c]}
        num_success += send_mock_github_events("push", curr_change)

    # Send fully associated push event
    num_success += send_mock_github_events("push", changes)

    # Make and send a deployment
    deploy = create_deploy_event(changes["head_commit"])
    num_success += send_mock_github_events("deployment", deploy)

    # 15% of deployments create incidents
    x = random.randrange(0, 100)
    if x < 15:
        issue = make_issue(changes["head_commit"])
        num_success += send_mock_github_events("issues", issue)

    return num_success


num_success = 0
for x in range(10):
    num_success += generate_data()

print(f"{num_success} changes successfully sent to event-handler")
