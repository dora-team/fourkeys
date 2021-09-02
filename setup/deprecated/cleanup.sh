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

# Bulk delete: if flag `-b` is specified, delete all projects with IDs that
# match patterns: fourkeys_* or helloworld_*

bulk_delete=0

while getopts ":b" opt; do
  case ${opt} in
    b ) bulk_delete=1  ;;
    \? ) echo "Usage: ./cleanup.sh [-b]" ;;
  esac
done

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [[ ${bulk_delete} -gt 0 ]]
then
    # disregard env variables and delete all projects matching "fourkeys-XXXXXX" or "helloworld-XXXXXX"
    projects=$(gcloud projects list --filter="projectId~^fourkeys-\d{6}$ OR projectId~^helloworld-\d{6}$" --format="value(projectId)")
else

    [[ -f "$DIR/env.sh" ]] && echo "Importing environment from $DIR/env.sh..." && . $DIR/env.sh

    projects="${FOURKEYS_PROJECT}"
    if [[ ! -z "${HELLOWORLD_PROJECT}" && ! -z "$(gcloud projects list --filter="projectId=${HELLOWORLD_PROJECT}" --format="value(projectId)")" ]]
    then
        projects="${FOURKEYS_PROJECT} ${HELLOWORLD_PROJECT}"
    fi
fi

if [ ! -z "${projects}" ]; then echo "Deleting projects..."; else echo "no projects to delete."; fi

for project in $projects; do
    echo "delete project ${project}..."
    gcloud projects delete "${project}"
done

if [ ! -z "${PARENT_PROJECT}" ]
then
    gcloud config set project ${PARENT_PROJECT}
fi

# purge env.sh file, if it exists
[[ -f "$DIR/env.sh" ]] && rm env.sh


