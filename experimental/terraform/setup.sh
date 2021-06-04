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

set -eEuo pipefail

echo "••••••••🔑••🔑••🔑••🔑••••••••"
printf "starting Four Keys setup…\n\n"

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

git_system=""
cicd_system=""

case $git_system_id in
    1) git_system="gitlab" ;;
    2) git_system="github" ;;
    *) echo "Please see the documentation to learn how to extend to VCS sources other than GitHub or GitLab"
esac

case $cicd_system_id in
    1) cicd_system="cloud-build" ;;
    2) cicd_system="tekton" ;;
    3) cicd_system="gitlab" ;;
    *) echo "Please see the documentation to learn how to extend to CI/CD sources other than Cloud Build, Tekton, GitLab, or GitHub."
esac

parsers=()
if [ $git_system == $cicd_system ]; then
    parsers+=("${git_system}")
else
    if [ ! -z "${git_system}" ]; then 
        parsers+=("${git_system}")
    fi
    if [ ! -z "${cicd_system}" ]; then
        parsers+=("${cicd_system}")
    fi
fi

echo $parsers

joined=""

for parser in "${parsers[@]}"; do
    joined="${joined},${parser}"
done

echo ${joined}

exit 0

RANDOM_IDENTIFIER=$((RANDOM%999999))
export PARENT_PROJECT=$(gcloud config get-value project)
export FOURKEYS_PROJECT=$(printf "fourkeys-%06d" $RANDOM_IDENTIFIER)
export FOURKEYS_REGION=us-central1
export PARENT_FOLDER=$(gcloud projects describe ${PARENT_PROJECT} --format="value(parent.id)")
export BILLING_ACCOUNT=$(gcloud beta billing projects describe ${PARENT_PROJECT} --format="value(billingAccountName)" || sed -e 's/.*\///g')
# TODO: support user-specified location
export BIGQUERY_REGION='US'

echo "••••••••🔑••🔑••🔑••🔑••••••••"
echo "Preparing environment…"

# TODO: Allow user to specify project name (or choose current)
echo "Creating new project for Four Keys Dashboard…"
gcloud projects create ${FOURKEYS_PROJECT} --folder=${PARENT_FOLDER}
gcloud beta billing projects link ${FOURKEYS_PROJECT} --billing-account=${BILLING_ACCOUNT}
export PARENT_PROJECTNUM=$(gcloud projects describe ${PARENT_PROJECT} --format='value(projectNumber)')

# FOR DEVELOPMENT ONLY: purge all TF state
echo "Purging TF state [FOR DEVELOPMENT ONLY]"
rm -rf .terraform terraform.tfstate* terraform.tfvars

# build service containers (using parent project) and store them in the fourkeys project
echo "••••••••🔑••🔑••🔑••🔑••••••••"
echo "Building containers…"
gcloud services enable cloudbuild.googleapis.com --project=${PARENT_PROJECT}
gcloud services enable containerregistry.googleapis.com --project=${FOURKEYS_PROJECT}
gcloud projects add-iam-policy-binding ${FOURKEYS_PROJECT} --member="serviceAccount:${PARENT_PROJECTNUM}@cloudbuild.gserviceaccount.com" --role="roles/storage.admin"

# launch container builds in background/parallel
gcloud builds submit ../../event_handler --tag=gcr.io/${FOURKEYS_PROJECT}/event-handler --project=${PARENT_PROJECT} > event_handler.containerbuild.log & 

for parser in 
gcloud builds submit ../../bq_workers/github_parser --tag=gcr.io/${FOURKEYS_PROJECT}/github-parser --project=${PARENT_PROJECT} > github_parser.containerbuild.log & 
gcloud builds submit ../../bq_workers/cloud_build_parser --tag=gcr.io/${FOURKEYS_PROJECT}/cloud-build-parser --project=${PARENT_PROJECT} > cloud_build_parser.containerbuild.log &

# wait for containers to be built, then continue
wait
echo "••••••••🔑••🔑••🔑••🔑••••••••"
echo "Invoking Terraform on project ${FOURKEYS_PROJECT}…"

# create a tfvars file
cat > terraform.tfvars <<EOF
google_project_id = "${FOURKEYS_PROJECT}"
google_region = "${FOURKEYS_REGION}"
bigquery_region = "${BIGQUERY_REGION}"
parsers = [${parsers}]
EOF

terraform init
terraform apply --auto-approve

echo "Terraform resource creation complete."
echo "••••••••🔑••🔑••🔑••🔑••••••••"

# TODO: make data generation optional
echo "generating data…"
WEBHOOK=$(terraform output -raw event-handler-endpoint) \
    SECRET=$(terraform output -raw event-handler-secret) \
    python3 ../../data_generator/generate_data.py --vc_system=github

echo "refreshing derived tables…"
for table in changes deployments incidents; do
    scheduled_query=$(bq ls --transfer_config --project_id=${FOURKEYS_PROJECT} --transfer_location=${BIGQUERY_REGION} | grep "four_keys_${table}" -m 1 | awk '{print $1;}')
    bq mk --transfer_run --project_id=${FOURKEYS_PROJECT} --run_time "$(date --iso-8601=seconds)" ${scheduled_query}
done

echo "••••••••🔑••🔑••🔑••🔑••••••••"
echo "configuring Data Studio dashboard…"
DATASTUDIO_URL="https://datastudio.google.com/datasources/create?connectorId=AKfycbxCOPCqhVOJQlRpOPgJ47dPZNdDu44MXbjsgKw_2-s"
python3 -m webbrowser ${DATASTUDIO_URL}
echo "Please visit $DATASTUDIO_URL to connect your data to the dashboard template."

echo "••••••••🔑••🔑••🔑••🔑••••••••"
echo 'Setup complete. Run the following commands to get values needed for GitHub webhook config:'
echo 'Webhook URL: `echo $(terraform output -raw event-handler-endpoint)`'
echo 'Secret: `echo $(terraform output -raw event-handler-secret)`'
