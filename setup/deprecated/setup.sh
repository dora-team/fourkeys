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
  RANDOM_IDENTIFIER=$((RANDOM%999999))
  export PARENT_PROJECT=$(gcloud config get-value project)
  export FOURKEYS_PROJECT=$(printf "fourkeys-%06d" $RANDOM_IDENTIFIER)
  export FOURKEYS_REGION=us-central1
  export HELLOWORLD_PROJECT=$(printf "helloworld-%06d" $RANDOM_IDENTIFIER)
  export HELLOWORLD_REGION=us-central
  export HELLOWORLD_ZONE=${HELLOWORLD_REGION}1-a
  export PARENT_FOLDER=$(gcloud projects describe ${PARENT_PROJECT} --format="value(parent.id)")
  export BILLING_ACCOUNT=$(gcloud beta billing projects describe ${PARENT_PROJECT} --format="value(billingAccountName)")

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
  export BILLING_ACCOUNT=$(gcloud beta billing projects describe ${FOURKEYS_PROJECT} --format="value(billingAccountName)")

  if [[ ! ${BILLING_ACCOUNT} ]]
  then echo "Please enable billing account on ${FOURKEYS_PROJECT}" 
  exit
  fi

  export FOURKEYS_REGION=us-central1

  echo "Setting up project for Four Keys Dashboard..." 
  get_project_number
  gcloud config set project ${FOURKEYS_PROJECT}; set -x
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

  echo "Setting Cloud Run options"; set -x
  gcloud config set run/platform managed
  gcloud config set run/region ${FOURKEYS_REGION}
  set +x; echo

  echo "Setting up service accounts and permissions.."; set -x
  gcloud projects add-iam-policy-binding ${FOURKEYS_PROJECT} \
    --member serviceAccount:${FOURKEYS_PROJECTNUM}@cloudbuild.gserviceaccount.com \
    --role roles/run.admin
  gcloud projects add-iam-policy-binding ${FOURKEYS_PROJECT} \
    --member serviceAccount:${FOURKEYS_PROJECTNUM}@cloudbuild.gserviceaccount.com \
    --role roles/iam.serviceAccountUser

  echo "Deploying event-handler..."; set -x
  cd $DIR/../../event-handler
  gcloud builds submit --substitutions _TAG=latest,_REGION=${FOURKEYS_REGION} .
  set +x; echo

  echo "Grant Cloud Pub/Sub the permission to create tokens..."; set -x
  export PUBSUB_SERVICE_ACCOUNT="service-${FOURKEYS_PROJECTNUM}@gcp-sa-pubsub.iam.gserviceaccount.com"
  gcloud projects add-iam-policy-binding ${FOURKEYS_PROJECT} \
    --member="serviceAccount:${PUBSUB_SERVICE_ACCOUNT}"\
    --role='roles/iam.serviceAccountTokenCreator'

  gcloud iam service-accounts create cloud-run-pubsub-invoker \
     --display-name "Cloud Run Pub/Sub Invoker"
  set +x; echo

  echo "Creating source pipelines"
  if [[ ${git_system} == "1" ]]
  then gitlab_pipeline
  fi
  if [[ ${git_system} == "2" ]]
  then github_pipeline
  else echo "Please see the documentation to learn how to extend to sources other than GitHub or GitLab"
  fi

  if [[ ${cicd_system} == "1" ]]
  then cloud_build_pipeline
  fi
  if [[ ${cicd_system} == "2" ]]
  then tekton_pipeline
  fi
  # Only set up GitLab pipeline if it wasn't selected as the version control system
  if [[ ${cicd_system} == "3" &&  ${git_system} != "1" ]] 
  then gitlab_pipeline
  else echo "Please see the documentation to learn how to extend to sources other than Cloud Build, Tekton, GitLab, or GitHub."
  fi


  echo "Creating BigQuery dataset and tables"; set -x
  bq mk \
    --dataset -f \
    ${FOURKEYS_PROJECT}:four_keys

  bq mk \
    --table -f\
    ${FOURKEYS_PROJECT}:four_keys.changes \
    $DIR/changes_schema.json

  bq mk \
    --table -f\
    ${FOURKEYS_PROJECT}:four_keys.deployments \
    $DIR/deployments_schema.json
  
  bq mk \
    --table -f\
    ${FOURKEYS_PROJECT}:four_keys.events_raw \
    $DIR/../events_raw_schema.json

  bq mk \
    --table -f\
    ${FOURKEYS_PROJECT}:four_keys.incidents \
    $DIR/incidents_schema.json
  set +x; echo

  # Create the json2array function
  bq query --nouse_legacy_sql $(cat ${DIR}/../../queries/json2array.sql)

  echo "Saving Event Handler Secret in Secret Manager.."
  # Set permissions so Cloud Run can access secrets
  SERVICE_ACCOUNT="${FOURKEYS_PROJECTNUM}-compute@developer.gserviceaccount.com"
  gcloud projects add-iam-policy-binding ${FOURKEYS_PROJECT} \
    --member=serviceAccount:$SERVICE_ACCOUNT \
    --role=roles/secretmanager.secretAccessor

  # Check if event-handler secret already exists
  check_secret=$(gcloud secrets versions access "1" --secret="event-handler" 2>/dev/null)
  if [[ $check_secret ]]
  then
  SECRET=$check_secret
  else

  # If not, create and save secret
  SECRET="$(python3 -c 'import secrets 
print(secrets.token_hex(20))' | tr -d '\n')"
  echo $SECRET | tr -d '\n' | gcloud beta secrets create event-handler \
    --replication-policy=automatic \
    --data-file=-
  fi
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

github_pipeline(){
  echo "Creating Github Data Pipeline..."

  echo "Deploying BQ github worker..."; set -x
  cd $DIR/../../bq-workers/github-parser
  gcloud builds submit --substitutions _TAG=latest,_REGION=${FOURKEYS_REGION} .
  set +x; echo

  echo "Creating Github Pub/Sub Topic & Subscription..."
  gcloud pubsub topics create github

  gcloud run services add-iam-policy-binding github-worker \
   --member="serviceAccount:cloud-run-pubsub-invoker@${FOURKEYS_PROJECT}.iam.gserviceaccount.com" \
   --role=roles/run.invoker

  # Get push endpoint for github-worker
  export PUSH_ENDPOINT_URL=$(gcloud run services describe github-worker --format="value(status.url)")
  # configure the subscription push identity
  gcloud pubsub subscriptions create GithubSubscription \
    --topic=github \
    --push-endpoint=${PUSH_ENDPOINT_URL} \
    --push-auth-service-account=cloud-run-pubsub-invoker@${FOURKEYS_PROJECT}.iam.gserviceaccount.com
  set +x; echo
  cd $DIR
}

gitlab_pipeline(){
  echo "Creating Gitlab Data Pipeline..."

  echo "Deploying BQ gitlab worker..."; set -x
  cd $DIR/../../bq-workers/gitlab-parser
  gcloud builds submit --substitutions _TAG=latest,_REGION=${FOURKEYS_REGION} .
  set +x; echo

  echo "Creating Github Pub/Sub Topic & Subscription..."
  gcloud pubsub topics create gitlab

  gcloud run services add-iam-policy-binding gitlab-worker \
   --member="serviceAccount:cloud-run-pubsub-invoker@${FOURKEYS_PROJECT}.iam.gserviceaccount.com" \
   --role=roles/run.invoker

  # Get push endpoint for gitlab-worker
  export PUSH_ENDPOINT_URL=$(gcloud run services describe gitlab-worker --format="value(status.url)")
  # configure the subscription push identity
  gcloud pubsub subscriptions create GitlabSubscription \
    --topic=gitlab \
    --push-endpoint=${PUSH_ENDPOINT_URL} \
    --push-auth-service-account=cloud-run-pubsub-invoker@${FOURKEYS_PROJECT}.iam.gserviceaccount.com
  set +x; echo
  cd $DIR
}


cloud_build_pipeline(){
  echo "Creating Cloud Build Data Pipeline..."

  echo "Deploying BQ cloud build worker..."; set -x
  cd $DIR/../../bq-workers/cloud-build-parser
  gcloud builds submit --substitutions _TAG=latest,_REGION=${FOURKEYS_REGION} . 
  set +x; echo

  echo "Creating cloud-builds topic..."; set -x
  gcloud pubsub topics create cloud-builds
  set +x; echo

  gcloud run services add-iam-policy-binding cloud-build-worker \
   --member="serviceAccount:cloud-run-pubsub-invoker@${FOURKEYS_PROJECT}.iam.gserviceaccount.com" \
   --role=roles/run.invoker

  # Get push endpoint for cloud-build-worker
  export PUSH_ENDPOINT_URL=$(gcloud run services describe cloud-build-worker --format="value(status.url)")
  # configure the subscription push identity
  gcloud pubsub subscriptions create CloudBuildSubscription \
    --topic=cloud-builds \
    --push-endpoint=${PUSH_ENDPOINT_URL} \
    --push-auth-service-account=cloud-run-pubsub-invoker@${FOURKEYS_PROJECT}.iam.gserviceaccount.com
  set +x; echo
  cd $DIR
}


tekton_pipeline(){
  echo "Creating Tekton Data Pipeline..."

  echo "Deploying BQ tekton worker..."; set -x
  cd $DIR/../../bq-workers/tekton-parser
  gcloud builds submit --substitutions _TAG=latest,_REGION=${FOURKEYS_REGION} .
  set +x; echo

  echo "Creating Tekton Pub/Sub Topic & Subscription..."
  gcloud pubsub topics create tekton

  gcloud run services add-iam-policy-binding tekton-worker \
   --member="serviceAccount:cloud-run-pubsub-invoker@${FOURKEYS_PROJECT}.iam.gserviceaccount.com" \
   --role=roles/run.invoker

  # Get push endpoint for tekton-worker
  export PUSH_ENDPOINT_URL=$(gcloud run services describe tekton-worker --format="value(status.url)")
  # configure the subscription push identity
  gcloud pubsub subscriptions create TektonSubscription \
    --topic=tekton \
    --push-endpoint=${PUSH_ENDPOINT_URL} \
    --push-auth-service-account=cloud-run-pubsub-invoker@${FOURKEYS_PROJECT}.iam.gserviceaccount.com
  set +x; echo
  cd $DIR
}


generate_data(){
  gcloud config set project ${FOURKEYS_PROJECT}
  echo "Creating mock data..."; 
  export WEBHOOK=$(gcloud run services describe event-handler --format="value(status.url)")
  export SECRET=$SECRET

  # Create an identity token if running in cloudbuild tests
  if [[ "$(gcloud config get-value account)" == "${FOURKEYS_PROJECTNUM}@cloudbuild.gserviceaccount.com" ]]
  then
  export TOKEN=$(curl -X POST -H "content-type: application/json" \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -d "{\"audience\": \"${WEBHOOK}\"}" \
    "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/cloud-run-pubsub-invoker@${FOURKEYS_PROJECT}.iam.gserviceaccount.com:generateIdToken" | \
    python3 -c "import sys, json; print(json.load(sys.stdin)['token'])")
  fi

  if [[ ${git_system} == "1" ]]
    then set -x; python3 ${DIR}/../../data-generator/generate_data.py --vc_system=gitlab
    set +x
  fi
    if [[ ${git_system} == "2" ]]
    then set -x; python3 ${DIR}/../../data-generator/generate_data.py --vc_system=github 
    set +x
  fi
  
}

schedule_bq_queries(){
  echo "Check BigQueryDataTransfer is enabled" 
  enabled=$(gcloud services list --enabled --filter name:bigquerydatatransfer.googleapis.com)

  while [[ "${enabled}" != *"bigquerydatatransfer.googleapis.com"* ]]
  do gcloud services enable bigquerydatatransfer.googleapis.com
  # Keep checking if it's enabled
  enabled=$(gcloud services list --enabled --filter name:bigquerydatatransfer.googleapis.com)
  done

  echo "Creating BigQuery scheduled queries for derived tables.."; set -x
  cd ${DIR}/../../queries/

  ./schedule.sh --query_file=changes.sql --table=changes --project_id=$FOURKEYS_PROJECT
  ./schedule.sh --query_file=deployments.sql --table=deployments --project_id=$FOURKEYS_PROJECT
  ./schedule.sh --query_file=incidents.sql --table=incidents --project_id=$FOURKEYS_PROJECT
  
  set +x; echo
  cd ${DIR}
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

get_project_number(){
  # There is sometimes a delay in the API and the gcloud command
  # Run the gcloud command until it returns a value
  continue=1
  while [[ ${continue} -gt 0 ]]
  do

  export FOURKEYS_PROJECTNUM=$(gcloud projects describe ${FOURKEYS_PROJECT} --format='value(projectNumber)')
  if [[ ${FOURKEYS_PROJECTNUM} ]]
  then continue=0
  fi

  done
}

check_bq_status(){
  echo "Waiting for BigQuery jobs to complete..." 
  continue=1
  while [[ ${continue} -gt 0 ]]
  do

  # Wait for BQ jobs to run
  jobStatus=$(bq ls -j -a -n 10 ${FOURKEYS_PROJECT})
  if [[ "${jobStatus}" != *"PENDING"* ]]
  then continue=0
  echo "BigQuery jobs done!"
  fi

  done
}

# # Main
read -p "Would you like to create a new Google Cloud Project for the four key metrics? (y/n):" new_yesno
if [[ ${new_yesno} == "y" ]]
then echo "Setting up the environment..."
environment
create_new_project
else project_prompt
fi

# Create workers for the correct sources
read -p "Which version control system are you using? 
(1) GitLab
(2) GitHub
(3) Other

Enter a selection (1 - 3):" git_system


read -p "Which CI/CD system are you using? 
(1) Cloud Build
(2) Tekton
(3) GitLab
(4) Other

Enter a selection (1 - 4):" cicd_system

fourkeys_project_setup

read -p "Would you like to create a separate new project to test deployments for the four key metrics? (y/n):" test_yesno
if [[ ${test_yesno} == "y" ]]
then environment
helloworld_project_setup
fi

read -p "Would you like to generate mock data? (y/n):" mock_yesno
if [[ ${mock_yesno} == "y" ]]
then generate_data
fi

schedule_bq_queries
check_bq_status

DATASTUDIO_URL="https://datastudio.google.com/datasources/create?connectorId=AKfycbxCOPCqhVOJQlRpOPgJ47dPZNdDu44MXbjsgKw_2-s"
python3 -m webbrowser ${DATASTUDIO_URL}
echo "Please visit $DATASTUDIO_URL to connect your data to the dashboard template."

echo "\nSetup complete.  To integrate with your own repo or other services, please see the README.md"
