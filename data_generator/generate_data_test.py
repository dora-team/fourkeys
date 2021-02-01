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

import generate_data

# from urllib.request import Request, urlopen

# methods to test
# make_changes(2, "github")
# make_changes(2, "gitlab")
# create_github_deploy_event(change)
# create_gitlab_pipeline_event(change)
# make_github_issue(root_cause) // root cause is a change
# make_gitlab_issue(changes)
# post_to_webhook(event_type, data, "github") // pick any one event type
# post_to_webhook(event_type, data, "gitlab") // pick any one event type

@pytest.fixture
def github_changes():
    return generate_data.make_changes(2, "github", 604800)

@pytest.fixture
def gitlab_changes():
    return generate_data.make_changes(2, "gitlab", 604800)

def test_changes_github(github_changes):

    # example of valid output
    # {'head_commit': {'id': 'c814b7082ba2ae5d2076568baa67a6b694845e42', 
    # 'timestamp': datetime.datetime(2021, 2, 1, 3, 38, 39, 923909)}, 
    # 'commits': [
    #   {'id': 'c814b7082ba2ae5d2076568baa67a6b694845e42', 
    #       'timestamp': datetime.datetime(2021, 2, 1, 3, 38, 39, 923909)}, 
    #   {'id': '3328c2fd3be8f20a5e072681cc5b2c86e644b839', 
    #       'timestamp': datetime.datetime(2021, 1, 28, 10, 28, 32, 923935)}]}

    # spot-check a few parts of the generated data
    assert len(github_changes['head_commit']['id']) == 40
    assert isinstance(github_changes['commits'][len(github_changes['commits'])-1]['timestamp'], datetime.datetime)

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
    assert isinstance(gitlab_changes['commits'][len(gitlab_changes['commits'])-1]['timestamp'], datetime.datetime)

def test_deploy_github(github_changes):

    # example output:
    # {'deployment_status': 
    #   {'updated_at': datetime.datetime(2021, 1, 29, 20, 2, 25, 104205), 
    #   'id': '14cdd47757a1ef343c4e183b457ff5cbe85a173b', 'state': 'success'}, 
    #   'deployment': {'sha': '189941869a9bee33fb03e1e18596ea55c4d892e2'}}

    deployment = generate_data.create_github_deploy_event(github_changes['head_commit'])
    
    # spot check generated data
    assert isinstance(deployment['deployment_status']['updated_at'], datetime.datetime)
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
    assert isinstance(deployment['object_attributes']['created_at'], datetime.datetime)
    assert deployment['object_attributes']['status'] == 'success'
    assert len(deployment['commit']['id']) == 40

# TODO: test_make_github_issue()
# TODO: test_make_gitlab_issue()

# TODO: post_to_webhook('github')

def test_post_webhook_github(httpserver,github_changes):
    
    # cloud run will return status 204 for a valid webhook post
    httpserver.serve_content('Received', 204)

    assert generate_data.post_to_webhook(
        'push', httpserver.url, github_changes, 'github', 'secret_string') == 1

# TODO: post_to_webhook('gitlab')

# TODO: consider factoring out the request object from 'post_to_webhook', so we can test
# that its headers are correct