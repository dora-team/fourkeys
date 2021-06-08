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

PARENT_PROJECT=$(gcloud config get-value project 2>/dev/null)

read -p "Would you like to create a new project for The Four Keys (y/N): " make_new_project
make_new_project=${make_new_project:-no}

if [ $make_new_project == 'y' ]; then
    echo "Creating new project for Four Keys Dashboard…"
    PARENT_FOLDER=$(gcloud projects describe ${PARENT_PROJECT} --format="value(parent.id)")
    BILLING_ACCOUNT=$(gcloud beta billing projects describe ${PARENT_PROJECT} --format="value(billingAccountName)" || sed -e 's/.*\///g')
    FOURKEYS_PROJECT=$(printf "fourkeys-%06d" $((RANDOM%999999)))
    FOURKEYS_REGION="us-central1"
    BIGQUERY_REGION="US"
    gcloud projects create ${FOURKEYS_PROJECT} --folder=${PARENT_FOLDER}
    gcloud beta billing projects link ${FOURKEYS_PROJECT} --billing-account=${BILLING_ACCOUNT}
else
    read -p "Enter the project ID for Four Keys installation (ex: 'my-project'): " FOURKEYS_PROJECT
    read -p "Enter the region for Four Keys resources (ex: 'us-central1'): " FOURKEYS_REGION
    read -p "Enter the location for Four Keys BigQuery resources (ex: 'US' or 'us-central1'): " BIGQUERY_REGION
fi

printf "\n"
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
(4) Other

Enter a selection (1 - 4): " cicd_system_id

GIT_SYSTEM=""
CICD_SYSTEM=""

case $git_system_id in
    1) GIT_SYSTEM="gitlab" ;;
    2) GIT_SYSTEM="github" ;;
    *) echo "Please see the documentation to learn how to extend to VCS sources other than GitHub or GitLab"
esac

case $cicd_system_id in
    1) CICD_SYSTEM="cloud-build" ;;
    2) CICD_SYSTEM="tekton" ;;
    3) CICD_SYSTEM="gitlab" ;;
    *) echo "Please see the documentation to learn how to extend to CI/CD sources other than Cloud Build, Tekton, GitLab, or GitHub."
esac

read -p "Would you like to generate mock data? (y/N): " generate_mock_data
generate_mock_data=${generate_mock_data:-no}

if [ $generate_mock_data == "y" ]; then
    GENERATE_DATA="yes"
else
    GENERATE_DATA="no"
fi

# FOR DEVELOPMENT ONLY: purge all TF state
echo "Purging TF state [FOR DEVELOPMENT ONLY]"
rm -rf .terraform terraform.tfstate* terraform.tfvars

# create a tfvars file
cat > terraform.tfvars <<EOF
google_project_id = "${FOURKEYS_PROJECT}"
google_region = "${FOURKEYS_REGION}"
bigquery_region = "${BIGQUERY_REGION}"
parsers = ["${GIT_SYSTEM}","${CICD_SYSTEM}"]
EOF

echo "••••••••🔑••🔑••🔑••🔑••••••••"
printf "starting Four Keys setup…\n\n"

terraform init
source install.sh