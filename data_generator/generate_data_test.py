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
import collections

import generate_data

def flatten(d,sep="_"):
    obj = collections.OrderedDict()

    def recurse(t,parent_key=""):
        
        if isinstance(t,list):
            for i in range(len(t)):
                recurse(t[i],parent_key + sep + str(i) if parent_key else str(i))
        elif isinstance(t,dict):
            for k,v in t.items():
                recurse(v,parent_key + sep + k if parent_key else k)
        else:
            obj[parent_key] = t

    recurse(d)

    return obj


def compare_dicts(dict_a, dict_b):
    
    # flatten any nested structures, so we only need one pass
    flat_dict_a = flatten(dict_a)
    flat_dict_b = flatten(dict_b)

    for key in flat_dict_a:

        assert type(flat_dict_a[key]) == type(flat_dict_b[key]), \
            f"type mismatch comparing '{key}': {type(flat_dict_a[key]).__name__} != {type(flat_dict_b[key]).__name__}"

        if isinstance(flat_dict_a[key], str):
            assert len(flat_dict_a[key]) == len(flat_dict_b[key]), \
                f"length mismatch comparing strings in '{key}': {len(flat_dict_a[key])} != {len(flat_dict_b[key])}"


@pytest.fixture
def github_changes():
    return generate_data.make_changes(2, "github", 604800)


@pytest.fixture
def gitlab_changes():
    return generate_data.make_changes(2, "gitlab", 604800)


@pytest.fixture
def valid_github_changes():

    # return an example of what valid data looks like
    valid_github_changes = {
        'head_commit': {
            'id': '29f54bb6cdb25a67dc7a2b7dae17a1346e2e9609',
            'timestamp': datetime.datetime(2021, 2, 1, 3, 38, 39, 923909)
        },
        'commits': [
            {'id': 'c814b7082ba2ae5d2076568baa67a6b694845e42',
             'timestamp': datetime.datetime(2021, 2, 1, 3, 38, 39, 923909)},
            {'id': '29f54bb6cdb25a67dc7a2b7dae17a1346e2e9609',
             'timestamp': datetime.datetime(2021, 1, 28, 10, 28, 32, 923935)}
        ]
    }

    return valid_github_changes


def test_changes_github(github_changes, valid_github_changes):
    compare_dicts(github_changes,valid_github_changes)


def test_changes_gitlab(gitlab_changes):

    # example of valid output
    # {'object_kind': 'push', 'checkout_sha': '29f54bb6cdb25a67dc7a2b7dae17a1346e2e9609',
    # 'commits': [
    #   {'id': '308ad3e4f9aa16c9c9873d61ace54002a8f5edb8',
    #   'timestamp': datetime.datetime(2021, 1, 29, 12, 13, 37, 98007)},
    #   {'id': '29f54bb6cdb25a67dc7a2b7dae17a1346e2e9609',
    #  'timestamp': datetime.datetime(2021, 2, 1, 16, 32, 16, 98023)}]}

    # spot-check a few parts of the generated data
    assert len(gitlab_changes['checkout_sha']) == 40
    assert isinstance(gitlab_changes['commits'][len(
        gitlab_changes['commits'])-1]['timestamp'], datetime.datetime)


def test_deploy_github(github_changes):

    # example output:
    # {'deployment_status':
    #   {'updated_at': datetime.datetime(2021, 1, 29, 20, 2, 25, 104205),
    #   'id': '14cdd47757a1ef343c4e183b457ff5cbe85a173b', 'state': 'success'},
    #   'deployment': {'sha': '189941869a9bee33fb03e1e18596ea55c4d892e2'}}

    deployment = generate_data.create_github_deploy_event(
        github_changes['head_commit'])

    # spot check generated data
    assert isinstance(deployment['deployment_status']
                      ['updated_at'], datetime.datetime)
    assert len(deployment['deployment_status']['id']) == 40
    assert len(deployment['deployment']['sha']) == 40


def test_deploy_gitlab(gitlab_changes):

    # example output:
    # {'object_kind': 'pipeline', 'object_attributes':
    #   {'created_at': datetime.datetime(2021, 1, 31, 19, 18, 31, 977940),
    #   'id': 856, 'status': 'success'},
    #   'commit': {'id': '70f6356d837c981651e6abd2079dc6d4915bae24',
    #   'timestamp': datetime.datetime(2021, 1, 31, 19, 18, 31, 977940)}}

    deployment = generate_data.create_gitlab_pipeline_event(gitlab_changes)

    # spot check generated data
    assert isinstance(deployment['object_attributes']
                      ['created_at'], datetime.datetime)
    assert deployment['object_attributes']['status'] == 'success'
    assert len(deployment['commit']['id']) == 40


def test_make_github_issue(github_changes):

    # example:
    # {'issue': {
    #   'created_at': datetime.datetime(2021, 1, 30, 22, 30, 5, 76942),
    #   'updated_at': datetime.datetime(2021, 2, 2, 21, 20, 58, 77232),
    #   'closed_at': datetime.datetime(2021, 2, 2, 21, 20, 58, 77235),
    #   'number': 440, 'labels': [{'name': 'Incident'}],
    #   'body': 'root cause: 2b04b6d3939608f19776193697e0e30c04d9c6b8'}}

    issue = generate_data.make_github_issue(github_changes['head_commit'])

    assert isinstance(issue['issue']['created_at'], datetime.datetime)
    assert isinstance(issue['issue']['closed_at'], datetime.datetime)
    assert isinstance(issue['issue']['number'], int)
    assert issue['issue']['labels'][0]['name'] == 'Incident'
    assert issue['issue']['body'].startswith('root cause: ')
    assert len(issue['issue']['body']) == 52


def test_make_gitlab_issue(gitlab_changes):

    # example:
    # {'object_kind': 'issue', 'object_attributes':
    #   {'created_at': datetime.datetime(2021, 1, 30, 17, 15, 36, 642384),
    #   'updated_at': datetime.datetime(2021, 2, 2, 21, 24, 21, 642669),
    #   'closed_at': datetime.datetime(2021, 2, 2, 21, 24, 21, 642672),
    #   'id': 764, 'labels': [{'title': 'Incident'}],
    #   'description': 'root cause: 51b14a84cbc2a8877c7b5b0986e15e37a259060b'}}

    issue = generate_data.make_gitlab_issue(gitlab_changes)

    print(issue)

    assert issue['object_kind'] == 'issue'
    assert isinstance(issue['object_attributes']
                      ['created_at'], datetime.datetime)
    assert isinstance(issue['object_attributes']
                      ['closed_at'], datetime.datetime)
    assert isinstance(issue['object_attributes']['id'], int)
    assert issue['object_attributes']['labels'][0]['title'] == 'Incident'
    assert issue['object_attributes']['description'].startswith('root cause: ')
    assert len(issue['object_attributes']['description']) == 52


def test_github_request(github_changes):

    request = generate_data.make_webhook_request(
        vcs='github',
        webhook_url='http://dummy_url',
        secret='dummy_secret_string',
        event_type='push',
        data=github_changes,
    )

    assert request.headers['X-github-event'] == 'push'
    assert request.headers['X-hub-signature'].startswith('sha1=')
    # ex: 'sha1=78492d6d232fafa4c58b31888cd131d1db9f5dd5'
    assert len(request.headers['X-hub-signature']) == 45
    assert request.headers['User-agent'] == 'GitHub-Hookshot/mock'
    assert request.headers['Content-type'] == 'application/json'
    assert request.headers['Mock'] is True
    # post body should contain at least one commit SHA
    assert len(request.data) >= 40


def test_gitlab_request(gitlab_changes):

    request = generate_data.make_webhook_request(
        vcs='gitlab',
        webhook_url='http://dummy_url',
        secret='dummy_secret_string',
        event_type='push',
        data=gitlab_changes,
    )

    assert request.headers['X-gitlab-event'] == 'push'
    assert request.headers['X-gitlab-token'] == 'dummy_secret_string'
    assert request.headers['Content-type'] == 'application/json'
    assert request.headers['Mock'] is True
    # post body should contain at least one commit SHA
    assert len(request.data) >= 40
