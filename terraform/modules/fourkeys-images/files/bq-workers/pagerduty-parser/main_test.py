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


def test_pagerduty_event_processed(client):
    data = json.dumps({"foo": "bar", "event": {"id": "foo", "occurred_at": 0, "event_type": "incident.triggered"}}).encode("utf-8")
    pubsub_msg = {
        "message": {
            "data": base64.b64encode(data).decode("utf-8"),
            "attributes": {"foo": "bar"},
            "message_id": "foobar",
        },
    }

    event = {
        "event_type": "incident.triggered",
        "id": "foo",
        "metadata": '{"foo": "bar", "event": {"id": "foo", "occurred_at": 0, "event_type": "incident.triggered"}}',
        "time_created": 0,
        "signature": "570ece386f1c03b9c91133b186c2c4a57857e255",
        "msg_id": "foobar",
        "source": "pagerduty",
    }

    shared.insert_row_into_bigquery = mock.MagicMock()

    r = client.post(
        "/",
        data=json.dumps(pubsub_msg),
        headers={"Content-Type": "application/json"},
    )

    shared.insert_row_into_bigquery.assert_called_with(event)
    assert r.status_code == 204
