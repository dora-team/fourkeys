#!/bin/bash
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

# This script configures installation variables, then invokes `install.sh`

set -eEuo pipefail

# PARSE INPUTS
CLEAN="false"
AUTO="false"
for i in "$@"
do
  case $i in
    -c | --clean ) CLEAN="true"; shift;;
    -a | --auto ) AUTO="true"; shift;;
    -h | --help ) echo "Usage: ./setup.sh [--clean] [--auto]"; exit 0; shift;;
    *) ;; # unknown option
  esac
done

if [[ ${AUTO} == 'true' ]]
then
    # populate setup variables (for use in testing/dev)
    git_system_id=2
    cicd_system_id=1
    incident_system_id=1
    generate_mock_data=y
    CLEAN='true'
else
    printf "\n"
    printf "Four Keys requires a Google Cloud project with billing enabled.\n"
    printf "If you don't have a suitable project, exit this installer and create a project.\n"

    read -p "Enter the project ID for Four Keys installation (ex: 'my-project'): " FOURKEYS_PROJECT
    read -p "Enter the region for Four Keys resources (ex: 'us-central1'): " FOURKEYS_REGION
    read -p "Enter the location for Four Keys BigQuery resources ('US' or 'EU'): " BIGQUERY_REGION

    read -p "Which version control system are you using? 
    (1) GitLab
    (2) GitHub
    (3) Other

    Enter a selection (1 - 3): " git_system_id

    read -p "
    Which CI/CD system are you using? 
    (1) Cloud Build
    (2) Tekton
    (3) GitLab
    (4) CircleCI
    (5) ArgoCD
    (6) Other

    Enter a selection (1 - 6): " cicd_system_id

    read -p "
    Which incident management system(s) are you using? 
    (1) PagerDuty
    (2) Other

    Enter a selection (1 - 2): " incident_system_id

    printf "\n"

    read -p "Would you like to generate mock data? (y/N): " generate_mock_data
    generate_mock_data=${generate_mock_data:-no}
fi

if [[ ${CLEAN} == 'true' ]]
then
    # purge all local terraform state
    rm -rf .terraform* *.containerbuild.log terraform.tfstate* terraform.tfvars
fi

printf "\n"

GIT_SYSTEM=""
CICD_SYSTEM=""
INCIDENT_SYSTEM=""
PAGERDUTY_SECRET=""

case $git_system_id in
    1) GIT_SYSTEM="gitlab" ;;
    2) GIT_SYSTEM="github" ;;
    *) echo "Please see the documentation to learn how to extend to VCS sources other than GitHub or GitLab"
esac

case $cicd_system_id in
    1) CICD_SYSTEM="cloud-build" ;;
    2) CICD_SYSTEM="tekton" ;;
    3) CICD_SYSTEM="gitlab" ;;
    4) CICD_SYSTEM="circleci" ;;
    5) CICD_SYSTEM="argocd" ;;
    *) echo "Please see the documentation to learn how to extend to CI/CD sources other than Cloud Build, Tekton, GitLab, CircleCI or GitHub."
esac

case $incident_system_id in
    1) INCIDENT_SYSTEM="pagerduty"; read -p "Please enter the PagerDuty Signature Verification Token: " PAGERDUTY_SECRET ;;
    *) echo "Please see the documentation to learn how to extend to incident sources other than PagerDuty."
esac

if [ "$PAGERDUTY_SECRET" != "" ]; then
    echo $PAGERDUTY_SECRET | tr -d '\n' | gcloud secrets create pager_duty_secret \
    --replication-policy=user-managed --locations ${FOURKEYS_REGION} \
    --data-file=-
fi

if [ $generate_mock_data == "y" ]; then
    GENERATE_DATA="yes"
else
    GENERATE_DATA="no"
fi

PARSERS=""
for PARSER in ${GIT_SYSTEM} ${CICD_SYSTEM} ${INCIDENT_SYSTEM}; do
    if [ "${PARSERS}" == "" ]; then
        PARSERS="\"${PARSER}\""
    else
        PARSERS+=",\"${PARSER}\""
    fi
done

# create a tfvars file
cat > terraform.tfvars <<EOF
google_project_id = "${FOURKEYS_PROJECT}"
google_region = "${FOURKEYS_REGION}"
bigquery_region = "${BIGQUERY_REGION}"
parsers = [${PARSERS}]
EOF

echo "••••••••🔑••🔑••🔑••🔑••••••••"
printf "starting Four Keys setup…\n\n"

terraform init

PARENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
source install.sh