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

# This script installs Four Keys; it requires several environment
# variables and terraform variables to be set; to set them interactively 
# and then launch installation, run `setup.sh`.

# REQUIRED ENVIRONMENT VARIABLES
# GIT_SYSTEM (e.g. "github")
# CICD_SYSTEM (e.g. "cloud-build")
# PARENT_PROJECT (the project that will orchestrate the install)
# FOURKEYS_PROJECT (the project to install Four Keys to)
# FOURKEYS_REGION (GCP region for cloud resources)
# BIGQUERY_REGION (location for BigQuery resources)
# GENERATE_DATA ["yes"|"no"]

# REQUIRED TERRAFORM VARIABLES
# google_project_id (FOURKEYS_PROJECT)
# google_region = (FOURKEYS_REGION)
# bigquery_region = (BIGQUERY_REGION)
# parsers = [(list of VCS and CICD parsers to install)]

set -eEuo pipefail

# color formatting shortcuts
export GREEN="\033[0;32m"
export NOCOLOR="\033[0m"

PARSERS=""
if [ $GIT_SYSTEM == $CICD_SYSTEM ]; then
    PARSERS="${GIT_SYSTEM}"
elif [ ! -z "${GIT_SYSTEM}" ] && [ ! -z "${CICD_SYSTEM}" ]; then
    PARSERS="${GIT_SYSTEM} ${CICD_SYSTEM}"
else
    PARSERS="${GIT_SYSTEM}${CICD_SYSTEM}"
fi

# build service containers (using parent project) and store them in the fourkeys project
echo "••••••••🔑••🔑••🔑••🔑••••••••"
echo "Building containers…"
gcloud services enable cloudbuild.googleapis.com
gcloud services enable containerregistry.googleapis.com --project=${FOURKEYS_PROJECT}
PARENT_PROJECTNUM=$(gcloud projects describe $(gcloud config get-value project) --format='value(projectNumber)')
gcloud projects add-iam-policy-binding ${FOURKEYS_PROJECT} --member="serviceAccount:${PARENT_PROJECTNUM}@cloudbuild.gserviceaccount.com" --role="roles/storage.admin"

# launch container builds in background/parallel
gcloud builds submit ../../event_handler --tag=gcr.io/${FOURKEYS_PROJECT}/event-handler --project=${PARENT_PROJECT} > event_handler.containerbuild.log & 

for parser in ${PARSERS}; do
    gcloud builds submit ../../bq-workers/${parser}-parser --tag=gcr.io/${FOURKEYS_PROJECT}/${parser}-parser --project=${PARENT_PROJECT} > ${parser}-parser.containerbuild.log & 
done

# wait for containers to be built, then continue
wait
echo "••••••••🔑••🔑••🔑••🔑••••••••"
echo "Invoking Terraform on project ${FOURKEYS_PROJECT}…"

terraform apply --auto-approve

echo "Terraform resource creation complete."
echo "••••••••🔑••🔑••🔑••🔑••••••••"

if [ $GENERATE_DATA == "yes" ]; then
    echo "generating data…"
    WEBHOOK=$(terraform output -raw event-handler-endpoint) \
        SECRET=$(terraform output -raw event-handler-secret) \
        python3 ../../data_generator/generate_data.py --vc_system=${GIT_SYSTEM}

    echo "refreshing derived tables…"
    for table in changes deployments incidents; do
        scheduled_query=$(bq ls --transfer_config --project_id=${FOURKEYS_PROJECT} --transfer_location=${BIGQUERY_REGION} | grep "four_keys_${table}" -m 1 | awk '{print $1;}')
        bq mk --transfer_run --project_id=${FOURKEYS_PROJECT} --run_time "$(date --iso-8601=seconds)" ${scheduled_query}
    done
fi

echo "••••••••🔑••🔑••🔑••🔑••••••••"
echo "configuring Data Studio dashboard…"
DATASTUDIO_URL="https://datastudio.google.com/datasources/create?connectorId=AKfycbxCOPCqhVOJQlRpOPgJ47dPZNdDu44MXbjsgKw_2-s"
python3 -m webbrowser ${DATASTUDIO_URL}
echo "Please visit $DATASTUDIO_URL to connect your data to the dashboard template."

echo "••••••••🔑••🔑••🔑••🔑••••••••"
echo 'Setup complete. Run the following commands to get values needed to configure VCS webhook:'
echo -e "➡️ Webhook URL: ${GREEN}echo \$(terraform output -raw event-handler-endpoint)${NOCOLOR}"
echo -e "➡️ Secret: ${GREEN}echo \$(terraform output -raw event-handler-secret)${NOCOLOR}"
