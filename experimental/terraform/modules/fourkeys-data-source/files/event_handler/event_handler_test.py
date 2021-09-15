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

import hmac
from hashlib import sha1

import event_handler

import mock
import pytest


@pytest.fixture
def client():
    event_handler.app.testing = True
    return event_handler.app.test_client()


def test_unauthorized_source(client):
    with pytest.raises(Exception) as e:
        client.post("/")

    assert "Source not authorized" in str(e.value)


def test_missing_signature(client):
    with pytest.raises(Exception) as e:
        client.post("/", headers={"User-Agent": "GitHub-Hookshot"})

    assert "Github signature is empty" in str(e.value)


@mock.patch("sources.get_secret", mock.MagicMock(return_value=b"foo"))
def test_unverified_signature(client):
    with pytest.raises(Exception) as e:
        client.post(
            "/",
            headers={
                "User-Agent": "GitHub-Hookshot",
                "X-Hub-Signature": "foobar",
            },
        )

    assert "Unverified Signature" in str(e.value)


@mock.patch("sources.get_secret", mock.MagicMock(return_value=b"foo"))
@mock.patch(
    "event_handler.publish_to_pubsub", mock.MagicMock(return_value=True)
)
def test_verified_signature(client):
    signature = "sha1=" + hmac.new(b"foo", b"Hello", sha1).hexdigest()
    r = client.post(
        "/",
        data="Hello",
        headers={"User-Agent": "GitHub-Hookshot", "X-Hub-Signature": signature},
    )
    assert r.status_code == 204


@mock.patch("sources.get_secret", mock.MagicMock(return_value=b"foo"))
def test_data_sent_to_pubsub(client):
    signature = "sha1=" + hmac.new(b"foo", b"Hello", sha1).hexdigest()
    event_handler.publish_to_pubsub = mock.MagicMock(return_value=True)
    headers = {
        "User-Agent": "GitHub-Hookshot",
        "Host": "localhost",
        "Content-Length": "5",
        "X-Hub-Signature": signature,
    }

    r = client.post("/", data="Hello", headers=headers)

    event_handler.publish_to_pubsub.assert_called_with(
        "github", b"Hello", headers
    )
    assert r.status_code == 204
