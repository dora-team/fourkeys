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

# set defaults
event_timespan = 604800
num_events = 20
num_issues = 2

# parse arguments
parser = argparse.ArgumentParser()
parser.add_argument("--event_timespan", "-t",
    help="time duration (in seconds) of timestamps of generated events (from [Now-timespan] to [Now]); default=604800 (1 week)")
parser.add_argument("--num_events", "-e", help="number of events to generate; default=20")
parser.add_argument("--num_issues", "-i", help="number of issues to generate; default=2")
parser.add_argument("--vc_system", "-v", help="version control system (e.g. 'github','gitlab')", required=True, choices=['gitlab','github'])
args = parser.parse_args()

# override defaults if specified in command line
if args.event_timespan:
    event_timespan = int(args.event_timespan)
if args.num_events:
    num_events = int(args.num_events)
if args.num_issues:
    num_issues = int(args.num_issues)

if num_issues > num_events:
    print("Error: num_issues cannot be greater than num_events")
    sys.exit()

def make_changes(num_changes):
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

    if args.vc_system == "gitlab":
        event = {"object_kind": "push",
             "checkout_sha": head_commit["id"],
             "commits": changes}
    if args.vc_system == "github":
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
        }
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
                    "status": "success"
                },
                "commit": c,
            }
    return pipeline

def make_github_issue(root_cause):
    
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
                }
            }
    return issue

def post_to_webhook(event_type, data):
    webhook_url = os.environ.get("WEBHOOK")
    data = json.dumps(data, default=str).encode()
    request = Request(webhook_url, data)
    
    if args.vc_system == "github":
        secret = os.environ.get("SECRET").encode()
        signature = hmac.new(secret, data, sha1)    
        request.add_header("X-Github-Event", event_type)
        request.add_header("X-Hub-Signature", "sha1=" + signature.hexdigest())
        request.add_header("User-Agent", "GitHub-Hookshot/mock")
    
    if args.vc_system == "gitlab":
        secret = os.environ.get("SECRET")
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

all_changesets = []
changes_sent = 0
for x in range(num_events):

    # make a change set containing a random number of changes
    changeset = make_changes(random.randrange(1,5))
    
    # Send individual changes data
    for c in changeset["commits"]:
        curr_change = None
        if args.vc_system == "gitlab":
            curr_change = {"object_kind": "push", "checkout_sha": c['id'], "commits": [c]}
        if args.vc_system == "github":
            curr_change = {"head_commit": c, "commits": [c]}
        changes_sent += post_to_webhook("push", curr_change)

    # Send fully associated push event
    post_to_webhook("push", changeset)

    # Make and send a deployment
    if args.vc_system == "gitlab":
        pipeline = create_gitlab_pipeline_event(changeset)
        post_to_webhook("pipeline",pipeline)

    if args.vc_system == "github":
        deploy = create_github_deploy_event(changeset["head_commit"])
        post_to_webhook("deployment_status", deploy)

    all_changesets.append(changeset)

# randomly create incidents associated to changes
changesets_with_issues = random.sample(all_changesets,num_issues)
for changeset in changesets_with_issues:
    issue = None
    if args.vc_system == "gitlab":
        issue = make_gitlab_issue(changeset)
    if args.vc_system == "github":
        issue = make_github_issue(changeset["head_commit"])
    post_to_webhook("issues",issue)

print(f"{changes_sent} changes successfully sent to event-handler")