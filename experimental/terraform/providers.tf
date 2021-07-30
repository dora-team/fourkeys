# Copyright 2020 Google LLC
# Copyright 2021 Nando’s Chickenland Limited
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

provider "google" {
  alias = "token"
}

data "google_service_account_access_token" "default" {
  provider               = google.token
  target_service_account = "terraform@${var.google_project_id}.iam.gserviceaccount.com"
  scopes                 = ["cloud-platform"]
  lifetime               = "3600s"
}

provider "google" {
  access_token = data.google_service_account_access_token.default.access_token
  project      = var.google_project_id
  region       = var.google_region
}

provider "google-beta" {
  access_token = data.google_service_account_access_token.default.access_token
  project      = var.google_project_id
  region       = var.google_region
}
