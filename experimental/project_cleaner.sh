#!/bin/bash
# This script will find any resources that *might* have been created by the Four Keys terraform installer
# and delete them from the specified project.
#
# ...with the following exceptions:
# - services that may have been enabled by the installer will not be disabled

set -eEuo pipefail

help() {
    printf "Usage: project_cleaner.sh --project_id=<google_cloud_project_id>\n"
    exit 0
}

PROJECT_ID=""
# PARSE INPUTS
for i in "$@"
do
case $i in
    -p=* | --project_id=*) 
    PROJECT_ID="${i#*=}"
    shift
    ;;
    -h | --help ) help; exit 0; shift;;
    *)
          # unknown option
    ;;
  esac
done

if [ -z "$PROJECT_ID" ]
then
    printf "Error: one or more required arguments not specified\n"
    help
    exit 1
fi

echo "Dropping BQ Resources:"
bq rm -r -f -d ${PROJECT_ID}:four_keys

echo "Dropping secret manager secrets:"
for secret_name in $(gcloud secrets list --filter="labels.created_by:fourkeys" --format="value(name)"); do
    gcloud secrets delete $secret_name --quiet
done

echo "Dropping Cloud Run services:"
for service in $(gcloud run services list --filter="metadata.labels.created_by:fourkeys" --format="value(name)"); do
    gcloud run services delete $service --quiet
done

echo "Dropping Pub/Sub topics:"
for topic in $(gcloud pubsub topics list --filter="labels.created_by:fourkeys" --format="value(name)"); do
    gcloud pubsub topics delete $topic --quiet
done

echo "Dropping Pub/Sub subscriptions:"
for subscription in $(gcloud pubsub subscriptions list --filter="labels.created_by:fourkeys" --format="value(name)"); do
    gcloud pubsub subscriptions delete $subscription --quiet
done

echo "Dropping service account:"
gcloud iam service-accounts delete fourkeys@${PROJECT_ID}.iam.gserviceaccount.com --quiet 