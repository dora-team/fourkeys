# Copyright 2020 Google LLC
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

import hmac
from hashlib import sha1, sha256
import os

from google.cloud import secretmanager

PROJECT_NAME = os.environ.get("PROJECT_NAME")


class EventSource(object):
    """
    A source of event data being delivered to the webhook
    """

    def __init__(self, signature_header, verification_func):
        self.signature = signature_header
        self.verification = verification_func


def github_verification(signature, body):
    """
    Verifies that the signature received from the github event is accurate
    """

    expected_signature = "sha1="
    try:
        # Get secret from Cloud Secret Manager
        secret = get_secret("event-handler")
        # Compute the hashed signature
        hashed = hmac.new(secret, body, sha1)
        expected_signature += hashed.hexdigest()

    except Exception as e:
        print(e)

    return hmac.compare_digest(signature, expected_signature)


def circleci_verification(signature, body):
    """
    Verifies that the signature received from the circleci event is accurate
    """

    expected_signature = "v1="
    try:
        # Get secret from Cloud Secret Manager
        secret = get_secret("event-handler")
        # Compute the hashed signature
        hashed = hmac.new(secret, body, sha256)
        expected_signature += hashed.hexdigest()

    except Exception as e:
        print(e)

    return hmac.compare_digest(signature, expected_signature)


def pagerduty_verification(signatures, body):
    """
    Verifies that the signature received from the pagerduty event is accurate
    """

    if not signatures:
        raise Exception("Pagerduty signature is empty")

    signature_list = signatures.split(",")

    if len(signature_list) == 0:
        raise Exception("Pagerduty signature list is empty")

    expected_signature = "v1="
    try:
        # Get secret from Cloud Secret Manager
        secret = get_secret("pagerduty_secret")

        # Compute the hashed signature
        hashed = hmac.new(secret, body, sha256)
        expected_signature += hashed.hexdigest()

    except Exception as e:
        print(e)

    if expected_signature in signature_list:
        return True
    else:
        return False


def sentry_verification(signature, body):
    """
    Verifies that the signature received from the sentry event is accurate
    """

    expected_signature = ""
    try:
        secret = get_secret("sentry_secret")
        hashed = hmac.new(secret, body, sha256)
        expected_signature = hashed.hexdigest()

    except Exception as e:
        print(e)

    return hmac.compare_digest(signature, expected_signature)


def simple_token_verification(token, body):
    """
    Verifies that the token received from the event is accurate
    """
    if not token:
        raise Exception("Token is empty")
    secret = get_secret("event-handler", "1")

    return secret.decode() == token


def get_secret(secret_name, secret_version="latest"):
    """
    Returns secret payload from Cloud Secret Manager
    """
    try:
        client = secretmanager.SecretManagerServiceClient()
        secret = client.access_secret_version(request={
            "name": f"projects/{PROJECT_NAME}/secrets/{secret_name}/versions/{secret_version}"
        })
        return secret.payload.data
    except Exception as e:
        print(e)


def get_source(headers):
    """
    Gets the source from the User-Agent header
    """
    if "X-Gitlab-Event" in headers:
        return "gitlab"

    if "tekton" in headers.get("Ce-Type", ""):
        return "tekton"

    if "GitHub-Hookshot" in headers.get("User-Agent", ""):
        return "github"

    if "Circleci-Event-Type" in headers:
        return "circleci"

    if "X-Pagerduty-Signature" in headers:
        return "pagerduty"

    if "Sentry-Hook-Resource" in headers:
        return "sentry"

    return headers.get("User-Agent")


AUTHORIZED_SOURCES = {
    "github": EventSource(
        "X-Hub-Signature", github_verification
    ),
    "gitlab": EventSource(
        "X-Gitlab-Token", simple_token_verification
    ),
    "tekton": EventSource(
        "tekton-secret", simple_token_verification
    ),
    "circleci": EventSource(
        "Circleci-Signature", circleci_verification
    ),
    "pagerduty": EventSource(
        "X-Pagerduty-Signature", pagerduty_verification
    ),
    "sentry": EventSource(
        "Sentry-Hook-Signature", sentry_verification
    ),
}
