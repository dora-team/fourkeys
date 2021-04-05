#!/bin/bash
#
# mockdataだけ初期化する


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

environment () {
  export FOURKEYS_PROJECT=hrb-fourkeys
}

fourkeys_project_setup () {
  echo "Setting up project for Four Keys Dashboard..." 
  get_project_number
  gcloud config set project ${FOURKEYS_PROJECT}; set -x
  set +x; echo

  # Check if event-handler secret already exists
  check_secret=$(gcloud beta secrets versions access "1" --secret="event-handler" 2>/dev/null)
  if [[ $check_secret ]]
  then
  SECRET=$check_secret
  fi
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

  set -x; python3 ${DIR}/../data_generator/generate_data.py --vc_system=github 
  set +x
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

# # Main
environment

fourkeys_project_setup

generate_data
