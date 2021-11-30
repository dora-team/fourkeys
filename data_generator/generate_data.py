# Copyright 2021 Google LLC
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

import argparse
import datetime
import hmac
import json
import os
import random
import secrets
import time
import sys

from hashlib import sha1
from urllib.request import Request, urlopen


def make_changes(num_changes, vcs, event_timespan):
    changes = []
    max_time = time.time() - event_timespan
    head_commit = None
    event = None

    for x in range(num_changes):
        change_id = secrets.token_hex(20)
        unix_timestamp = time.time() - random.randrange(0, event_timespan)
        change = {
            "id": change_id,
            "timestamp": datetime.datetime.fromtimestamp(unix_timestamp),
        }

        if unix_timestamp > max_time:
            max_time = unix_timestamp
            head_commit = change

        changes.append(change)

    if vcs == "gitlab":
        event = {
            "object_kind": "push",
            "checkout_sha": head_commit["id"],
            "commits": changes,
        }
    if vcs == "github":
        event = {"head_commit": head_commit, "commits": changes}

    return event


def create_github_deploy_event(change):
    deployment = {
        "deployment_status": {
            "updated_at": change["timestamp"],
            "id": secrets.token_hex(20),
            "state": "success",
        },
        "deployment": {
            "sha": change["id"],
        },
    }
    return deployment


def create_gitlab_pipeline_event(changes):
    pipeline = None
    checkout_sha = changes["checkout_sha"]
    for c in changes["commits"]:
        if c["id"] == checkout_sha:
            pipeline = {
                "object_kind": "pipeline",
                "object_attributes": {
                    "created_at": c["timestamp"],
                    "id": random.randrange(0, 1000),
                    "status": "success",
                },
                "commit": c,
            }
    return pipeline


def create_gitlab_deploy_event(changes):
    deployment = None
    checkout_sha = changes["checkout_sha"]
    for c in changes["commits"]:
        if c["id"] == checkout_sha:
            deployment = {
                "object_kind": "deployment",
                "status": "success",
                "status_changed_at": c["timestamp"].strftime("%F %T +0200"),
                "deployment_id": random.randrange(0, 1000),
                "commit_url": f"http://example.com/root/test/commit/{checkout_sha}",
            }
    return deployment


def make_github_issue(root_cause):
    event = {
        "issue": {
            "created_at": root_cause["timestamp"],
            "updated_at": datetime.datetime.now(),
            "closed_at": datetime.datetime.now(),
            "number": random.randrange(0, 1000),
            "labels": [{"name": "Incident"}],
            "body": "root cause: %s" % root_cause["id"],
        },
        "repository": {"name": "foobar"},
    }
    return event


def make_gitlab_issue(changes):
    issue = None
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
                },
            }
    return issue


def make_webhook_request(vcs, webhook_url, secret, event_type, data, token=None):
    data = json.dumps(data, default=str).encode()
    request = Request(webhook_url, data)

    if vcs == "github":
        signature = hmac.new(secret.encode(), data, sha1)
        request.add_header("X-Github-Event", event_type)
        request.add_header("X-Hub-Signature", "sha1=" + signature.hexdigest())
        request.add_header("User-Agent", "GitHub-Hookshot/mock")

    if vcs == "gitlab":
        request.add_header("X-Gitlab-Event", event_type)
        request.add_header("X-Gitlab-Token", secret)

    request.add_header("Content-Type", "application/json")
    request.add_header("Mock", True)

    if token:
        request.add_header("Authorization", f"Bearer {token}")

    return request


def post_to_webhook(vcs, webhook_url, secret, event_type, data, token=None):

    request = make_webhook_request(vcs, webhook_url, secret, event_type, data, token)

    response = urlopen(request)

    if response.getcode() == 204:
        return 1
    else:
        return 0


if __name__ == "__main__":
    # parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--event_timespan",
        "-t",
        type=int,
        default=604800,
        help="time duration (in seconds) of timestamps of generated events \
                        (from [Now-timespan] to [Now]); default=604800 (1 week)",
    )
    parser.add_argument(
        "--num_events",
        "-e",
        type=int,
        default=20,
        help="number of events to generate; default=20",
    )
    parser.add_argument(
        "--num_issues",
        "-i",
        type=int,
        default=2,
        help="number of issues to generate; default=2",
    )
    parser.add_argument(
        "--vc_system",
        "-v",
        required=True,
        choices=["gitlab", "github"],
        help="version control system (e.g. 'github', 'gitlab')",
    )
    args = parser.parse_args()

    if args.num_issues > args.num_events:
        print("Error: num_issues cannot be greater than num_events")
        sys.exit()

    # get environment vars
    webhook_url = os.environ.get("WEBHOOK")
    secret = os.environ.get("SECRET")
    token = os.environ.get("TOKEN")

    if not webhook_url or not secret:
        print(
            "Error: please ensure the following environment variables are set: WEBHOOK, SECRET"
        )
        sys.exit()

    all_changesets = []
    changes_sent = 0
    for x in range(args.num_events):

        # make a change set containing a random number of changes
        changeset = make_changes(
            random.randrange(1, 5),
            args.vc_system,
            args.event_timespan,
        )

        # Send individual changes data
        for c in changeset["commits"]:
            curr_change = None
            if args.vc_system == "gitlab":
                curr_change = {
                    "object_kind": "push",
                    "checkout_sha": c["id"],
                    "commits": [c],
                }
            if args.vc_system == "github":
                curr_change = {"head_commit": c, "commits": [c]}
            changes_sent += post_to_webhook(
                args.vc_system, webhook_url, secret, "push", curr_change, token
            )

        # Send fully associated push event
        post_to_webhook(args.vc_system, webhook_url, secret, "push", changeset, token)

        # Make and send a deployment
        if args.vc_system == "gitlab":
            deploy = create_gitlab_deploy_event(changeset)
            post_to_webhook(
                args.vc_system, webhook_url, secret, "deployment", deploy, token
            )

        if args.vc_system == "github":
            deploy = create_github_deploy_event(changeset["head_commit"])
            post_to_webhook(
                args.vc_system, webhook_url, secret, "deployment_status", deploy, token
            )

        all_changesets.append(changeset)

    # randomly create incidents associated to changes
    changesets_with_issues = random.sample(all_changesets, args.num_issues)
    for changeset in changesets_with_issues:
        issue = None
        if args.vc_system == "gitlab":
            issue = make_gitlab_issue(changeset)
        if args.vc_system == "github":
            issue = make_github_issue(changeset["head_commit"])
        post_to_webhook(args.vc_system, webhook_url, secret, "issues", issue, token)

    print(f"{changes_sent} changes successfully sent to event-handler")
