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

from absl import app
from absl import flags

import datetime
import json
import random
import os
import secrets
import time

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

    event = {"object_kind": "push",
             "checkout_sha": head_commit["id"],
             "commits": changes}
    return event


def make_issue(changes):
    checkout_sha = changes["checkout_sha"]
    for c in changes["commits"]:
        if c["id"] == checkout_sha:
            issue = {
                "object_kind": "issue",
                "object_attributes": {
                    "created_at": c["timestamp"],
                    "updated_at": datetime.datetime.now(),
                    "closed_at": datetime.datetime.now(),
                    "id": random.randrange(0, 1000),
                    "labels": [{"title": "Incident"}],
                    "description": "root cause: %s" % c["id"],
                }
            }
    return issue


def send_mock_gitlab_events(event_type, data):
    webhook_url = os.environ.get("WEBHOOK")
    data = json.dumps(data, default=str).encode()
    secret = os.environ.get("SECRET")

    request = Request(webhook_url, data)
    request.add_header("X-Gitlab-Event", event_type)
    request.add_header("X-Gitlab-Token", secret)
    request.add_header("Content-Type", "application/json")
    request.add_header("Mock", True)

    token = os.environ.get("TOKEN")
    if token:
        request.add_header("Authorization", f"Bearer {token}")

    response = urlopen(request)

    if response.getcode() == 204:
        return 1
    else:
        return 0


def create_pipeline_event(changes):
    checkout_sha = changes["checkout_sha"]
    for c in changes["commits"]:
        if c["id"] == checkout_sha:
            pipeline = {
                "object_kind": "pipeline",
                "object_attributes": {
                    "created_at": c["timestamp"],
                    "id": random.randrange(0, 1000),
                    "status": "success"
                },
                "commit": c,
            }
    return pipeline


def generate_data():
    num_success = 0
    changes = make_changes(2)

    # Send individual changes data
    for c in changes["commits"]:
        curr_change = {"object_kind": "push", "checkout_sha": c['id'], "commits": [c]}
        num_success += send_mock_gitlab_events("push", curr_change)

    # Send fully associated push event
    num_success += send_mock_gitlab_events("push", changes)

    # Make and send a deployment
    pipeline = create_pipeline_event(changes)
    num_success += send_mock_gitlab_events("pipeline", pipeline)

    # # 15% of deployments create incidents
    x = random.randrange(0, 100)
    if x < 15:
        issue = make_issue(changes)
        num_success += send_mock_gitlab_events("issue", issue)

    return num_success


num_success = 0
for x in range(100):
    num_success += generate_data()

print(f"{num_success} changes successfully sent to event-handler")
