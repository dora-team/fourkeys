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

# This script will create or update BigQuery scheduled queries for each
# of the derived tables.

# Usage: 
# `schedule.sh --query_file=<filename_of_source_query> \
#  --table=<target_table> --project_id=<GCP_project_containing_dataset>`

help() {
    printf "Usage: schedule.sh --query_file=<filename_of_source_query> --table=<target_table> --project_id=<GCP_project_containing_dataset>\n"
}

# PARSE INPUTS
for i in "$@"
do
case $i in
    -q=*|--query_file=*) 
    QUERY_FILE="${i#*=}"
    shift 
    ;;
    -t=* | --table=*) 
    TABLE="${i#*=}"
    shift 
    ;;
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

if [[ -z "$QUERY_FILE" || -z "$TABLE" || -z "$PROJECT_ID" ]]
then
    printf "Error: one or more required arguments not specified\n"
    help
    exit 1
fi

echo QUERY_FILE=$QUERY_FILE
echo TABLE=$TABLE
echo PROJECT_ID=$PROJECT_ID

# SCHEDULE THE QUERY

# First, delete the transfer config, if it exists
for location in US EU; do
    while [ ! -z "$(bq ls --transfer_config --transfer_location=$location --project_id=$PROJECT_ID | grep "$TABLE" -m 1 | awk '{print $1;}')" ]
    do
        scheduled_query=$(bq ls --transfer_config --transfer_location=$location --project_id=$PROJECT_ID | grep "$TABLE" -m 1 | awk '{print $1;}')
        echo "deleting prior scheduled query for $TABLE: $scheduled_query"
        bq rm --force --transfer_config $scheduled_query
    done
done

bq query \
    --project_id=$PROJECT_ID \
    --use_legacy_sql=false \
    --destination_table=$PROJECT_ID:four_keys.$TABLE \
    --display_name=four_keys_$TABLE \
    --schedule="every 24 hours" \
    --replace=true \
    --label=created_by:four_keys \
    "`cat $QUERY_FILE`"