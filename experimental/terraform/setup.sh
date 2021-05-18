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

echo "••••••••🔑🔑🔑🔑••••••••"
echo "starting Four Keys setup…"

RANDOM_IDENTIFIER=$((RANDOM%999999))
export PARENT_PROJECT=$(gcloud config get-value project)
export FOURKEYS_PROJECT=$(printf "fourkeys-%06d" $RANDOM_IDENTIFIER)
export FOURKEYS_REGION=us-central1
# export HELLOWORLD_PROJECT=$(printf "helloworld-%06d" $RANDOM_IDENTIFIER)
# export HELLOWORLD_REGION=us-central
# export HELLOWORLD_ZONE=${HELLOWORLD_REGION}1-a
export PARENT_FOLDER=$(gcloud projects describe ${PARENT_PROJECT} --format="value(parent.id)")
export BILLING_ACCOUNT=$(gcloud beta billing projects describe ${PARENT_PROJECT} --format="value(billingAccountName)" || sed -e 's/.*\///g')

echo "••••••••🔑🔑🔑🔑••••••••"
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
echo "••••••••🔑🔑🔑🔑••••••••"
echo "Building containers…"
gcloud services enable cloudbuild.googleapis.com --project=${PARENT_PROJECT}
gcloud services enable containerregistry.googleapis.com --project=${FOURKEYS_PROJECT}
gcloud projects add-iam-policy-binding ${FOURKEYS_PROJECT} --member="serviceAccount:${PARENT_PROJECTNUM}@cloudbuild.gserviceaccount.com" --role="roles/storage.admin"

# launch container builds in background/parallel
gcloud builds submit ../../event_handler --tag=gcr.io/${FOURKEYS_PROJECT}/event-handler --project=${PARENT_PROJECT} & 
gcloud builds submit ../../bq_workers/github_parser --tag=gcr.io/${FOURKEYS_PROJECT}/github-parser --project=${PARENT_PROJECT} & 
gcloud builds submit ../../bq_workers/cloud_build_parser --tag=gcr.io/${FOURKEYS_PROJECT}/cloud-build-parser --project=${PARENT_PROJECT} &

# wait for containers to be built, then continue
wait
echo "••••••••🔑🔑🔑🔑••••••••"
echo "Invoking Terraform on project ${FOURKEYS_PROJECT}…"

# create a tfvars file
cat > terraform.tfvars <<EOF
google_project_id = "${FOURKEYS_PROJECT}"
google_region = "${FOURKEYS_REGION}"
EOF

terraform init
terraform apply --auto-approve

echo "Terraform resource creation complete."
echo "••••••••🔑🔑🔑🔑••••••••"

# TODO: make data generation optional
echo "generating data…"
# TODO: allow passing of webhook / secret as params to data generator
export WEBHOOK=$(terraform output -raw event-handler-endpoint)
export SECRET=$(terraform output -raw event-handler-secret)
python3 ../../data_generator/generate_data.py --vc_system=github

# TODO: at completion of script, add instructions/outputs for configuring webhooks
echo "••••••••🔑🔑🔑🔑••••••••"
echo 'Setup complete. To get the values needed to configure GitHub, run the following commands:'
echo 'To get the webhook URL, run: "echo $(terraform output -raw event-handler-endpoint)"'
echo 'To get the webhook secret, run: "echo $(terraform output -raw event-handler-secret)"'
