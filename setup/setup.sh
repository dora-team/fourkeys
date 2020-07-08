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


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

environment () {
  # Set values that will be overwritten if env.sh exists
  export PARENT_PROJECT=$(gcloud config get-value project)
  export FOURKEYS_PROJECT=$(printf "fourkeys-%06d" $((RANDOM%999999)))
  export FOURKEYS_REGION=us-central1
  export HELLOWORLD_PROJECT=$(printf "helloworld-%06d" $((RANDOM%999999)))
  export HELLOWORLD_REGION=us-central
  export HELLOWORLD_ZONE=${HELLOWORLD_REGION}1-a
  export PARENT_FOLDER=$(gcloud projects describe ${PARENT_PROJECT} --format="value(parent.id)")
  export BILLING_ACCOUNT=$(gcloud beta billing projects describe ${PARENT_PROJECT} --format="value(billingAccountName)" || sed -e 's/.*\///g')

  export PYTHONHTTPSVERIFY=0

  [[ -f "$DIR/env.sh" ]] && echo "Importing environment from $DIR/env.sh..." && . $DIR/env.sh
  echo "Writing $DIR/env.sh..."
  cat > $DIR/env.sh << EOF
export FOURKEYS_PROJECT=${FOURKEYS_PROJECT}
export FOURKEYS_REGION=${FOURKEYS_REGION}
export HELLOWORLD_PROJECT=${HELLOWORLD_PROJECT}
export HELLOWORLD_ZONE=${HELLOWORLD_ZONE}
export BILLING_ACCOUNT=${BILLING_ACCOUNT}
export PARENT_PROJECT=${PARENT_PROJECT}
export PARENT_FOLDER=${PARENT_FOLDER}
EOF
}

create_new_project(){
  echo "Creating new project for Four Keys Dashboard..."; set -x
  gcloud projects create ${FOURKEYS_PROJECT} --folder=${PARENT_FOLDER}
  gcloud beta billing projects link ${FOURKEYS_PROJECT} --billing-account=${BILLING_ACCOUNT}

  set +x; echo
}

fourkeys_project_setup () {
  # Check that the Four Keys Project has a billing account
  export BILLING_ACCOUNT=$(gcloud beta billing projects describe ${FOURKEYS_PROJECT} --format="value(billingAccountName)" || sed -e 's/.*\///g')

  if [[ ! ${BILLING_ACCOUNT} ]]
  then echo "Please enable billing account on ${FOURKEYS_PROJECT}" 
  exit
  fi

  export FOURKEYS_REGION=us-central1
  export SSH_PRIVATE_KEY=$(cat ~/.ssh/id_rsa)

  echo "Setting up project for Four Keys Dashboard..."; set -x
  export FOURKEYS_PROJECTNUM=$(gcloud projects list --filter="${FOURKEYS_PROJECT}" --format="value(PROJECT_NUMBER)")
  gcloud config set project ${FOURKEYS_PROJECT}
  set +x; echo

  echo "Enabling apis..."; set -x
  gcloud services enable compute.googleapis.com
  gcloud services enable run.googleapis.com
  gcloud services enable cloudbuild.googleapis.com
  gcloud services enable pubsub.googleapis.com
  gcloud services enable containerregistry.googleapis.com
  gcloud services enable bigquery.googleapis.com
  gcloud services enable bigquerydatatransfer.googleapis.com
  gcloud services enable bigqueryconnection.googleapis.com
  gcloud services enable secretmanager.googleapis.com
  set +x; echo

  echo "Setting up service accounts and permissions.."; set -x
  gcloud projects add-iam-policy-binding ${FOURKEYS_PROJECT} \
    --member serviceAccount:${FOURKEYS_PROJECTNUM}@cloudbuild.gserviceaccount.com \
    --role roles/run.admin
  gcloud projects add-iam-policy-binding ${FOURKEYS_PROJECT} \
    --member serviceAccount:${FOURKEYS_PROJECTNUM}@cloudbuild.gserviceaccount.com \
    --role roles/iam.serviceAccountUser

  echo "Creating Github event handler Pub/Sub topic..."; set -x
  gcloud pubsub topics create GitHub-Hookshot
  set +x; echo

  echo "Creating Gitlab event handler Pub/Sub topic..."; set -x
  gcloud pubsub topics create Gitlab
  set +x; echo

  echo "Creating cloud-builds topic..."; set -x
  gcloud pubsub topics create cloud-builds
  set +x; echo

  echo "Deploying event handler..."; set -x
  cd $DIR/../event_handler
  gcloud builds submit --substitutions _TAG=latest,_REGION=${FOURKEYS_REGION} .
  set +x; echo

  echo "Deploying BQ github worker..."; set -x
  cd $DIR/../bq_workers/github_parser
  gcloud builds submit --substitutions _TAG=latest,_REGION=${FOURKEYS_REGION} .
  set +x; echo

  echo "Deploying BQ cloud build worker..."; set -x
  cd $DIR/../bq_workers/cloud_build_parser
  gcloud builds submit --substitutions _TAG=latest,_REGION=${FOURKEYS_REGION} . 
  set +x; echo

  echo "Creating BQ worker Pub/Sub subscription..."; set -x
  # grant Cloud Pub/Sub the permission to create tokens
  export PUBSUB_SERVICE_ACCOUNT="service-${FOURKEYS_PROJECTNUM}@gcp-sa-pubsub.iam.gserviceaccount.com"
  gcloud projects add-iam-policy-binding ${FOURKEYS_PROJECT} \
    --member="serviceAccount:${PUBSUB_SERVICE_ACCOUNT}"\
    --role='roles/iam.serviceAccountTokenCreator'
  gcloud iam service-accounts create cloud-run-pubsub-invoker \
     --display-name "Cloud Run Pub/Sub Invoker"
  gcloud run  --platform managed services add-iam-policy-binding github-worker \
   --member="serviceAccount:cloud-run-pubsub-invoker@${FOURKEYS_PROJECT}.iam.gserviceaccount.com" \
   --role=roles/run.invoker
  gcloud run  --platform managed services add-iam-policy-binding cloud-build-worker \
   --member="serviceAccount:cloud-run-pubsub-invoker@${FOURKEYS_PROJECT}.iam.gserviceaccount.com" \
   --role=roles/run.invoker

  # Get push endpoint for github-worker
  export PUSH_ENDPOINT_URL=$(gcloud run --platform managed --region ${FOURKEYS_REGION} services describe github-worker --format=yaml | grep url | head -1 | sed -e 's/  *url: //g')
  # configure the subscription push identity
  gcloud pubsub subscriptions create GithubSubscription \
    --topic=GitHub-Hookshot \
    --push-endpoint=${PUSH_ENDPOINT_URL} \
    --push-auth-service-account=cloud-run-pubsub-invoker@${FOURKEYS_PROJECT}.iam.gserviceaccount.com
  set +x; echo

  # Get push endpoint for cloud-build-worker
  export PUSH_ENDPOINT_URL=$(gcloud run --platform managed --region ${FOURKEYS_REGION} services describe cloud-build-worker --format=yaml | grep url | head -1 | sed -e 's/  *url: //g')
  # configure the subscription push identity
  gcloud pubsub subscriptions create CloudBuildSubscription \
    --topic=cloud-builds \
    --push-endpoint=${PUSH_ENDPOINT_URL} \
    --push-auth-service-account=cloud-run-pubsub-invoker@${FOURKEYS_PROJECT}.iam.gserviceaccount.com
  set +x; echo

  echo "Creating BigQuery dataset and tables"; set -x
  bq mk \
    --dataset \
    ${FOURKEYS_PROJECT}:four_keys

  bq mk \
    --table \
    ${FOURKEYS_PROJECT}:four_keys.changes \
    $DIR/changes_schema.json

  bq mk \
    --table \
    ${FOURKEYS_PROJECT}:four_keys.deployments \
    $DIR/deployments_schema.json
  
  bq mk \
    --table \
    ${FOURKEYS_PROJECT}:four_keys.events_raw \
    $DIR/events_raw_schema.json

  bq mk \
    --table \
    ${FOURKEYS_PROJECT}:four_keys.incidents \
    $DIR/incidents_schema.json
  set +x; echo

  echo "Saving Github Secret in Secret Manager.."; set -x\
  # Set permissions so Cloud Run can access secrets
  SERVICE_ACCOUNT=$(gcloud iam service-accounts list --format 'value(EMAIL)' \
    --filter 'NAME:Default compute service account')
  gcloud projects add-iam-policy-binding ${FOURKEYS_PROJECT} \
    --member=serviceAccount:$SERVICE_ACCOUNT \
    --role=roles/secretmanager.secretAccessor

  # Create and save secret
  SECRET="$(python3 -c 'import secrets 
print(secrets.token_hex(20))' | tr -d '\n')"
  echo $SECRET | tr -d '\n' | gcloud beta secrets create github-secret \
    --replication-policy=automatic \
    --data-file=-
  set +x; echo
}

helloworld_project_setup () {
  echo "Setting up project for Helloworld..."; set -x
  gcloud projects create ${HELLOWORLD_PROJECT} --folder=${PARENT_FOLDER}
  gcloud beta billing projects link ${HELLOWORLD_PROJECT} --billing-account=${BILLING_ACCOUNT}
  gcloud config set project ${HELLOWORLD_PROJECT}
  set +x; echo

  echo "Enabling apis..."; set -x
  gcloud services enable compute.googleapis.com
  gcloud services enable cloudbuild.googleapis.com
  gcloud services enable run.googleapis.com
  gcloud services enable containerregistry.googleapis.com
  set +x; echo

  echo "Cloning Helloworld demo..."; set -x
  cd $DIR
  git clone https://github.com/knative/docs.git
  set +x

  echo "Building default helloworld app..."; set -x
  cd ${DIR}/docs/docs/serving/samples/hello-world/helloworld-python
  gcloud builds submit --tag gcr.io/${HELLOWORLD_PROJECT}/helloworld .
  set +x

  echo "Deploying to staging..."; set -x
  gcloud run deploy helloworld-staging --image gcr.io/${HELLOWORLD_PROJECT}/helloworld --allow-unauthenticated
  set +x

  echo "Deploying to prod..."; set -x
  gcloud run deploy helloworld-prod --image gcr.io/${HELLOWORLD_PROJECT}/helloworld --allow-unauthenticated
  set +x

}

generate_data(){
  gcloud config set project ${FOURKEYS_PROJECT}
  echo "Creating mock data..."; 
  export WEBHOOK=$(gcloud run --platform managed --region ${FOURKEYS_REGION} services describe event-handler --format=yaml | grep url | head -1 | sed -e 's/  *url: //g')
  export GITHUB_SECRET=$SECRET

  set -x
  python3 ${DIR}/../data_generator/data.py
  set +x
}

schedule_bq_queries(){
  echo "Creating BigQuery scheduled queries for derived tables.."; set -x
  bq mk \
    --transfer_config \
    --project_id=${FOURKEYS_PROJECT} \
    --target_dataset=four_keys \
    --display_name='Changes Table' \
    --data_source=scheduled_query \
    --params='{"destination_table_name_template":"changes",
               "write_disposition":"WRITE_TRUNCATE",
               "query":"SELECT id as change_id, time_created, event_type FROM four_keys.events_raw WHERE event_type in (\"pull_request\", \"push\") GROUP BY 1,2,3;"}'

  bq mk \
    --transfer_config \
    --project_id=${FOURKEYS_PROJECT} \
    --target_dataset=four_keys \
    --display_name='Deployments Table' \
    --data_source=scheduled_query \
    --params='{"destination_table_name_template":"deployments",
               "write_disposition":"WRITE_TRUNCATE",
               "query":"CREATE TEMP FUNCTION json2array(json STRING) RETURNS ARRAY<STRING> LANGUAGE js AS \"\"\" return JSON.parse(json).map(x=>JSON.stringify(x)); \"\"\"; SELECT deploy_id, time_created, ARRAY_AGG(DISTINCT JSON_EXTRACT_SCALAR(changes, \"$.id\")) changes FROM( SELECT deploy_id, deploys.time_created time_created, change_metadata, json2array(JSON_EXTRACT(change_metadata, \"$.commits\")) array_commits FROM (SELECT id as deploy_id, time_created, IF(source = \"cloud_build\", JSON_EXTRACT_SCALAR(metadata, \"$.substitutions.COMMIT_SHA\"), JSON_EXTRACT_SCALAR(metadata, \"$.deployment.sha\")) as main_commit FROM four_keys.events_raw WHERE (source = \"cloud_build\" AND JSON_EXTRACT_SCALAR(metadata, \"$.status\") = \"SUCCESS\") OR (source LIKE \"github%\" and event_type = \"deployment\") ) deploys JOIN (SELECT id, metadata as change_metadata FROM four_keys.events_raw) changes on deploys.main_commit = changes.id) d, d.array_commits changes GROUP BY 1,2 ;"}'

  bq mk \
    --transfer_config \
    --project_id=${FOURKEYS_PROJECT} \
    --target_dataset=four_keys \
    --display_name='Incidents Table' \
    --data_source=scheduled_query \
    --params='{"destination_table_name_template":"incidents",
               "write_disposition":"WRITE_TRUNCATE",
               "query":"SELECT incident_id, TIMESTAMP(time_created) time_created, TIMESTAMP(MAX(time_resolved)) as time_resolved, ARRAY_AGG(root_cause IGNORE NULLS) changes, FROM ( SELECT JSON_EXTRACT_SCALAR(metadata, \"$.issue.number\") as incident_id, JSON_EXTRACT_SCALAR(metadata, \"$.issue.created_at\") as time_created, JSON_EXTRACT_SCALAR(metadata, \"$.issue.closed_at\") as time_resolved, REGEXP_EXTRACT(metadata, r\"root cause: ([[:alnum:]]*)\") as root_cause, REGEXP_CONTAINS(JSON_EXTRACT(metadata, \"$.issue.labels\"), \"\\\"name\\\":\\\"Incident\\\"\") as bug FROM four_keys.events_raw WHERE event_type LIKE \"issue%\") GROUP BY 1,2 HAVING max(bug) is True;"}'
  set +x; echo
}

project_prompt(){
  # Confirm project is the correct one to use for four-keys
  continue=1
  while [[ ${continue} -gt 0 ]]
  do

  # Prompt until project-id is correct
  if [[ ${FOURKEYS_PROJECT} ]]
  then read -p "Would you like to use ${FOURKEYS_PROJECT} to deploy a new Cloud Run worker? (y/n) :" yesno
  fi 

  if [[ ${yesno} == "y" ]]
  then continue=0
  else read -p "Please input project_id: " projectid
  export FOURKEYS_PROJECT=${projectid}
  fi

  done
}

#Main
read -p "Would you like to create a new Google Cloud Project for the four key metrics? (y/n):" new_yesno
if [[ ${new_yesno} == "y" ]]
then echo "Setting up the environment..."
environment
create_new_project
else project_prompt
fi

fourkeys_project_setup

read -p "Would you like to create a separate new project to test deployments for the four key metrics? (y/n):" test_yesno
if [[ ${test_yesno} == "y" ]]
then helloworld_project_setup
fi

read -p "Would you like to generate mock data? (y/n):" mock_yesno
if [[ ${mock_yesno} == "y" ]]
then generate_data
fi
schedule_bq_queries

python -m webbrowser https://datastudio.google.com/datasources/create?connectorId=AKfycbxCOPCqhVOJQlRpOPgJ47dPZNdDu44MXbjsgKw_2-s

echo "Setup complete.  To integrate with your own repo or other services, please see the README.md"