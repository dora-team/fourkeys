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


def test_prometheus_event_processed(client):
    data_content = {
            "receiver":"fourkeys",
            "status":"firing",
            "alerts":[
                {
                    "status":"firing",
                    "startsAt":"2022-10-07T10:26:18.249Z",
                    "endsAt":"0001-01-01T00:00:00Z",
                    "fingerprint":"1144cel0"
                }
            ],
        }
    
    data = json.dumps(data_content).encode("utf-8")

    pubsub_msg = {
        "message": {
            "data": base64.b64encode(data).decode("utf-8"),
            "attributes": {"foo": "bar"},
            "message_id": "foobar",
        },
    }

    event = {
        "event_type": "incident.triggered",
        "id": "1144cel0",
        "metadata": '{"status": "firing", "startsAt": "2022-10-07T10:26:18.249Z", "endsAt": "0001-01-01T00:00:00Z", "fingerprint": "1144cel0"}',
        "time_created": "2022-10-07T10:26:18.249Z",
        "signature": "511081853ca1163faf1b1825358becb013752881",
        "msg_id": "foobar",
        "source": "prometheus",
    }

    shared.insert_row_into_bigquery = mock.MagicMock()

    r = client.post(
        "/",
        data=json.dumps(pubsub_msg),
        headers={"Content-Type": "application/json"},
    )

    shared.insert_row_into_bigquery.assert_called_with(event)
    assert r.status_code == 204
