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


def test_sentry_event_processed(client):
    data = json.dumps({
        "action": "created",
        "installation": {
            "uuid": "95cc9015-1456-4656-83fb-df3fa930348e"
        },
        "data": {
            "issue": {
                "id": "3359227809",
                "shareId": None,
                "shortId": "PROJECT-NAME",
                "title": "Your exception: Cannot continue.",
                "culprit": "com.google.common.base.Preconditions in checkState",
                "permalink": None,
                "logger": "com.logger.name",
                "level": "warning",
                "status": "unresolved",
                "statusDetails": {},
                "isPublic": False,
                "platform": "rust",
                "project": {
                    "id": "5303212330",
                    "name": "name",
                    "slug": "name",
                    "platform": "rust"
                },
                "type": "error",
                "metadata": {
                    "value": "Cannot continue.",
                    "type": "YourException",
                    "filename": "Preconditions.java",
                    "function": "checkState",
                    "display_title_with_tree_label": False
                },
                "numComments": 0,
                "assignedTo": None,
                "isBookmarked": False,
                "isSubscribed": False,
                "subscriptionDetails": None,
                "hasSeen": False,
                "annotations": [],
                "isUnhandled": False,
                "count": "1",
                "userCount": 0,
                "firstSeen": "2022-06-01T00:50:02.780000Z",
                "lastSeen": "2022-06-18T13:50:02.780000Z"
            }
        },
        "actor": {
            "type": "application",
            "id": "sentry",
            "name": "Sentry"
        }
    }).encode("utf-8")
    pubsub_msg = {
        "message": {
            "data": base64.b64encode(data).decode("utf-8"),
            "attributes": {
                "headers": json.dumps({
                    "Content-Type": "application/json",
                    "Request-ID": "ef0dd634-e830-4aa4-a690-5fca54a11a18",
                    "Sentry-Hook-Resource": "issue",
                    "Sentry-Hook-Timestamp": "2022-03-06T11:31:64.118160Z",
                    "Sentry-Hook-Signature": "<generated_signature>"
                })
            },
            "message_id": "foobar",
        },
    }

    event = {
        "event_type": "issue",
        "id": "3359227809",
        "metadata": data.decode("utf-8"),
        "time_created": "2022-03-06T11:31:64.118160Z",
        "signature": "<generated_signature>",
        "msg_id": "foobar",
        "source": "sentry",
    }

    shared.insert_row_into_bigquery = mock.MagicMock()

    r = client.post(
        "/",
        data=json.dumps(pubsub_msg),
        headers={"Content-Type": "application/json"},
    )

    shared.insert_row_into_bigquery.assert_called_with(event)
    assert r.status_code == 204


def test_unsupported_sentry_event_processed(client):
    data = json.dumps({
        "action": "created",
        "data": {
            "comment": "adding a comment",
            "project_slug": "sentry",
            "comment_id": 1234,
            "issue_id": 100,
            "timestamp": "2022-03-02T21:51:44.118160Z"
        },
        "installation": {"uuid": "eac5a0ae-60ec-418f-9318-46dc5e7e52ec"},
        "actor": {"type": "user", "id": 1, "name": "Rikkert"}
    }).encode("utf-8")
    pubsub_msg = {
        "message": {
            "data": base64.b64encode(data).decode("utf-8"),
            "attributes": {
                "headers": json.dumps({
                    "Content-Type": "application/json",
                    "Request-ID": "ef0dd634-e830-4aa4-a690-5fca54a11a18",
                    "Sentry-Hook-Resource": "comment",
                    "Sentry-Hook-Timestamp": "2022-03-06T11:31:64.118160Z",
                    "Sentry-Hook-Signature": "<generated_signature>"
                })
            },
            "message_id": "foobar",
        },
    }

    shared.insert_row_into_bigquery = mock.MagicMock()

    r = client.post(
        "/",
        data=json.dumps(pubsub_msg),
        headers={"Content-Type": "application/json"},
    )

    shared.insert_row_into_bigquery.assert_not_called()
    assert r.status_code == 204
