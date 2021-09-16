#!/bin/bash
# This script will find any resources that *might* have been created by the Four Keys terraform installer
# and delete them from the specified project.
#
# ...with the following exceptions:
# - services that may have been enabled by the installer will not be disabled

set -eEuo pipefail

help() {
    printf "Usage: project_cleaner.sh --project=<google_cloud_project_id>\n"
    exit 0
}


# PARSE INPUTS
PROJECT_ID=""
for i in "$@"
do
case $i in
    -p=* | --project=*) PROJECT_ID="${i#*=}"; shift;;
    -h | --help ) help; exit 0; shift;;
    *) ;;  # unknown option
  esac
done

if [ -z "$PROJECT_ID" ]
then
    printf "Error: one or more required arguments not specified\n"
    help
    exit 1
fi

echo "🗑 Dropping BQ Resources…"
set -x
bq rm -r -f -d ${PROJECT_ID}:four_keys || true
set +x

echo "🗑 Dropping secret manager secrets…"
set -x
for secret_name in $(gcloud secrets list --project=$PROJECT_ID --filter="labels.created_by:fourkeys" --uri); do
    gcloud secrets delete $secret_name --quiet
done
set +x

echo "🗑 Dropping Cloud Run services…"

set -x
for service in $(gcloud run services list --project=$PROJECT_ID --filter="metadata.labels.created_by:fourkeys" --uri); do
    gcloud run services delete $service --quiet
done
set +x

echo "🗑 Dropping Pub/Sub topics…"
set -x
for topic in $(gcloud pubsub topics list --project=$PROJECT_ID --filter="labels.created_by:fourkeys" --uri); do
    gcloud pubsub topics delete $topic --quiet
done
set +x

echo "🗑 Dropping Pub/Sub subscriptions…"
set -x
for subscription in $(gcloud pubsub subscriptions list --project=$PROJECT_ID --filter="labels.created_by:fourkeys" --uri); do
    gcloud pubsub subscriptions delete $subscription --quiet
done
set +x

echo "🗑 Dropping service account…"
set -x
gcloud iam service-accounts delete fourkeys@${PROJECT_ID}.iam.gserviceaccount.com --quiet || true
set +x

echo "✅ Done."