# Copyright 2021 Google, LLC.
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

import pytest
import datetime

from urllib.request import Request

from util_compare_dicts import compare_dicts

import generate_data


@pytest.fixture
def generate_changes(vcs):
    return generate_data.make_changes(2, vcs, 604800)


@pytest.fixture
def generate_all_changesets(vcs):
    return generate_data.make_all_changesets(10, vcs, 604800)


@pytest.fixture
def generate_ind_changes(vcs, generate_all_changesets):
    for changeset in generate_all_changesets:
        yield generate_data.make_ind_changes_from_changeset(changeset, vcs)


@pytest.fixture
def generate_deployment(vcs, generate_changes):
    if vcs == "github":
        return generate_data.create_github_deploy_event(generate_changes["head_commit"])
    elif vcs == "gitlab":
        return generate_data.create_gitlab_deploy_event(generate_changes)


@pytest.fixture
def generate_issue(vcs, generate_changes):
    if vcs == "github":
        return generate_data.make_github_issue(generate_changes["head_commit"])
    elif vcs == "gitlab":
        return generate_data.make_gitlab_issue(generate_changes)


@pytest.fixture
def make_change_request(vcs, generate_changes):
    return generate_data.make_webhook_request(
        vcs=vcs,
        webhook_url="http://dummy_url",
        secret="dummy_secret_string",
        event_type="push",
        data=generate_changes,
    )


@pytest.fixture
def valid_changes(vcs):

    # return an example of what valid data looks like
    if vcs == "github":
        return {
            "head_commit": {
                "id": "29f54bb6cdb25a67dc7a2b7dae17a1346e2e9609",
                "timestamp": datetime.datetime(2021, 2, 1, 3, 38, 39, 923909),
            },
            "before": "50b2c21f17f97e040707665a2da5288cdc766e8a",
            "commits": [
                {
                    "id": "c814b7082ba2ae5d2076568baa67a6b694845e42",
                    "timestamp": datetime.datetime(2021, 2, 1, 3, 38, 39, 923909),
                },
                {
                    "id": "29f54bb6cdb25a67dc7a2b7dae17a1346e2e9609",
                    "timestamp": datetime.datetime(2021, 1, 28, 10, 28, 32, 923935),
                },
            ],
        }

    elif vcs == "gitlab":
        return {
            "object_kind": "push",
            "before": "50b2c21f17f97e040707665a2da5288cdc766e8a",
            "checkout_sha": "29f54bb6cdb25a67dc7a2b7dae17a1346e2e9609",
            "commits": [
                {
                    "id": "308ad3e4f9aa16c9c9873d61ace54002a8f5edb8",
                    "timestamp": datetime.datetime(2021, 1, 29, 12, 13, 37, 98007),
                },
                {
                    "id": "29f54bb6cdb25a67dc7a2b7dae17a1346e2e9609",
                    "timestamp": datetime.datetime(2021, 2, 1, 16, 32, 16, 98023),
                },
            ],
        }


@pytest.fixture
def valid_deployment(vcs):

    if vcs == "github":
        return {
            "deployment_status": {
                "updated_at": datetime.datetime(2021, 1, 29, 20, 2, 25, 104205),
                "id": "14cdd47757a1ef343c4e183b457ff5cbe85a173b",
                "state": "success",
            },
            "deployment": {"sha": "189941869a9bee33fb03e1e18596ea55c4d892e2"},
        }
    elif vcs == "gitlab":
        return {
            "object_kind": "deployment",
            "status": "success",
            "status_changed_at": "2021-04-28 21:50:00 +0200",
            "deployment_id": 856,
            "commit_url": "http://example.com/root/test/commit/3c8427100e3dadd90daf1e01105b41284cf42c76",
        }


@pytest.fixture
def valid_issue(vcs):
    if vcs == "github":
        return {
            "issue": {
                "created_at": datetime.datetime(2021, 1, 30, 22, 30, 5, 76942),
                "updated_at": datetime.datetime(2021, 2, 2, 21, 20, 58, 77232),
                "closed_at": datetime.datetime(2021, 2, 2, 21, 20, 58, 77235),
                "number": 440,
                "labels": [{"name": "Incident"}],
                "body": "root cause: 2b04b6d3939608f19776193697e0e30c04d9c6b8",
            },
            "repository": {"name": "foobar"},
        }
    elif vcs == "gitlab":
        return {
            "object_kind": "issue",
            "object_attributes": {
                "created_at": datetime.datetime(2021, 1, 30, 17, 15, 36, 642384),
                "updated_at": datetime.datetime(2021, 2, 2, 21, 24, 21, 642669),
                "closed_at": datetime.datetime(2021, 2, 2, 21, 24, 21, 642672),
                "id": 764,
                "labels": [{"title": "Incident"}],
                "description": "root cause: 51b14a84cbc2a8877c7b5b0986e15e37a259060b",
            },
        }


@pytest.fixture
def valid_change_request(vcs, generate_changes):

    request = Request(
        url="http://dummy_url",
        data=generate_changes,
        headers={"Content-type": "application/json", "Mock": True},
    )

    if vcs == "github":
        request.add_header("X-github-event", "push")
        request.add_header(
            "X-hub-signature", "sha1=73a9ef6ce9bda2b769807691ddacfe3caf50f4e0"
        )
        request.add_header("User-agent", "GitHub-Hookshot/mock")
    elif vcs == "gitlab":
        request.add_header("X-gitlab-event", "push")
        request.add_header("X-gitlab-token", "dummy_secret_string")

    return request


@pytest.mark.parametrize("vcs", ["github", "gitlab"])
def test_changes(generate_changes, valid_changes):
    assert compare_dicts(generate_changes, valid_changes) == "pass", compare_dicts


@pytest.mark.parametrize("vcs", ["github", "gitlab"])
def test_deployment(valid_deployment, generate_deployment):
    assert compare_dicts(generate_deployment, valid_deployment) == "pass", compare_dicts


@pytest.mark.parametrize("vcs", ["github", "gitlab"])
def test_issue(valid_issue, generate_issue):
    assert compare_dicts(generate_issue, valid_issue) == "pass", compare_dicts


@pytest.mark.parametrize("vcs", ["github", "gitlab"])
def test_request(valid_change_request, make_change_request):
    assert (
        compare_dicts(make_change_request.headers, valid_change_request.headers)
        == "pass"
    ), compare_dicts


@pytest.mark.parametrize("vcs", ["github", "gitlab"])
def test_all_changesets_linked_with_before_attribute(generate_all_changesets):
    all_changesets = generate_all_changesets
    for i in range(1, len(all_changesets)):
        prev_change_sha = (all_changesets[i - 1].get("checkout_sha")
                           or all_changesets[i - 1].get("head_commit", {}).get("id"))
        assert all_changesets[i]["before"] == prev_change_sha


@pytest.mark.parametrize("vcs", ["github", "gitlab"])
def test_ind_change_from_changeset_linked_with_before_attribute(vcs, generate_all_changesets):
    for changeset in generate_all_changesets:
        ind_changes = generate_data.make_ind_changes_from_changeset(changeset, vcs)

        for i in range(1, len(ind_changes)):
            prev_change_sha = ind_changes[i - 1].get("checkout_sha") or ind_changes[i - 1].get("head_commit", {}).get("id")
            assert ind_changes[i]["before"] == prev_change_sha
