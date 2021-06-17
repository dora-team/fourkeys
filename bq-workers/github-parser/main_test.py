# Copyright 2020 Google, LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import base64
import json

import main
import shared

import mock
import pytest


@pytest.fixture
def client():
    main.app.testing = True
    return main.app.test_client()


def test_not_json(client):
    with pytest.raises(Exception) as e:
        client.post("/", data="foo")

    assert "Expecting JSON payload" in str(e.value)


def test_not_pubsub_message(client):
    with pytest.raises(Exception) as e:
        client.post(
            "/",
            data=json.dumps({"foo": "bar"}),
            headers={"Content-Type": "application/json"},
        )

    assert "Not a valid Pub/Sub Message" in str(e.value)


def test_missing_msg_attributes(client):
    with pytest.raises(Exception) as e:
        client.post(
            "/",
            data=json.dumps({"message": "bar"}),
            headers={"Content-Type": "application/json"},
        )

    assert "Missing pubsub attributes" in str(e.value)


def test_github_event_processed(client):
    headers = {"X-Github-Event": "push", "X-Hub-Signature": "foo"}
    commit = json.dumps({"head_commit": {"timestamp": 0, "id": "bar"}}).encode(
        "utf-8"
    )
    pubsub_msg = {
        "message": {
            "data": base64.b64encode(commit).decode("utf-8"),
            "attributes": {"headers": json.dumps(headers)},
            "message_id": "foobar",
        },
    }

    github_event = {
        "event_type": "push",
        "id": "bar",
        "metadata": '{"head_commit": {"timestamp": 0, "id": "bar"}}',
        "time_created": 0,
        "signature": "foo",
        "msg_id": "foobar",
        "source": "github",
    }

    shared.insert_row_into_bigquery = mock.MagicMock()

    r = client.post(
        "/",
        data=json.dumps(pubsub_msg),
        headers={"Content-Type": "application/json"},
    )

    shared.insert_row_into_bigquery.assert_called_with(github_event)
    assert r.status_code == 204


def test_github_event_avoid_id_conflicts_pull_requests(client):

    headers = {"X-Github-Event": "pull_request", "X-Hub-Signature": "foo"}
    commit = json.dumps({
        "pull_request": {
            "updated_at": "2021-06-15T13:12:14Z"
        },
        "repository": {
            "name": "reponame"
        },
        "number": 477
    }).encode("utf-8")

    encoded_commit = {
        "data": base64.b64encode(commit).decode("utf-8"),
        "attributes": {"headers": json.dumps(headers)},
        "message_id": "foobar",
    }

    github_event_calculated = main.process_github_event(headers=headers, msg=encoded_commit)
    github_event_expected = {
        "id": "reponame/477"
    }

    assert github_event_calculated["id"] == github_event_expected["id"]


def test_github_event_avoid_id_conflicts_issues(client):

    headers = {"X-Github-Event": "issues", "X-Hub-Signature": "foo"}
    commit = json.dumps({
        "issue": {
            "updated_at": "2021-06-15T13:12:14Z",
            "number": 477
        },
        "repository": {
            "name": "reponame"
        }
    }).encode("utf-8")

    encoded_commit = {
        "data": base64.b64encode(commit).decode("utf-8"),
        "attributes": {"headers": json.dumps(headers)},
        "message_id": "foobar",
    }

    github_event_calculated = main.process_github_event(headers=headers, msg=encoded_commit)
    github_event_expected = {
        "id": "reponame/477"
    }

    assert github_event_calculated["id"] == github_event_expected["id"]
