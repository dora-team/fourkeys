resource "google_bigquery_table" "" {
  dataset_id = "four_keys"
  labels {
    managed-by-cnrm = "true"
  }
  project  = "fourkeys-000182"
  schema   = "[{\"mode\":\"NULLABLE\",\"name\":\"source\",\"type\":\"STRING\"},{\"mode\":\"NULLABLE\",\"name\":\"change_id\",\"type\":\"STRING\"},{\"mode\":\"NULLABLE\",\"name\":\"time_created\",\"type\":\"TIMESTAMP\"},{\"mode\":\"NULLABLE\",\"name\":\"event_type\",\"type\":\"STRING\"}]"
  table_id = "changes"
}
resource "google_bigquery_table" "" {
  dataset_id = "four_keys"
  labels {
    managed-by-cnrm = "true"
  }
  project  = "fourkeys-000182"
  schema   = "[{\"mode\":\"NULLABLE\",\"name\":\"source\",\"type\":\"STRING\"},{\"mode\":\"NULLABLE\",\"name\":\"deploy_id\",\"type\":\"STRING\"},{\"mode\":\"NULLABLE\",\"name\":\"time_created\",\"type\":\"TIMESTAMP\"},{\"mode\":\"REPEATED\",\"name\":\"changes\",\"type\":\"STRING\"}]"
  table_id = "deployments"
}
resource "google_bigquery_dataset" "" {
  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }
  access {
    role          = "OWNER"
    user_by_email = "davidstanke@gmail.com"
  }
  access {
    role          = "READER"
    special_group = "projectReaders"
  }
  access {
    role          = "WRITER"
    special_group = "projectWriters"
  }
  access {
    role          = "WRITER"
    user_by_email = "service-528445800720@gcp-sa-bigquerydatatransfer.iam.gserviceaccount.com"
  }
  dataset_id                 = "four_keys"
  delete_contents_on_destroy = false
  labels {
    managed-by-cnrm = "true"
  }
  location = "US"
  project  = "fourkeys-000182"
}
resource "google_bigquery_table" "" {
  dataset_id = "four_keys"
  labels {
    managed-by-cnrm = "true"
  }
  project  = "fourkeys-000182"
  schema   = "[{\"mode\":\"NULLABLE\",\"name\":\"event_type\",\"type\":\"STRING\"},{\"mode\":\"NULLABLE\",\"name\":\"id\",\"type\":\"STRING\"},{\"mode\":\"NULLABLE\",\"name\":\"metadata\",\"type\":\"STRING\"},{\"mode\":\"NULLABLE\",\"name\":\"time_created\",\"type\":\"TIMESTAMP\"},{\"mode\":\"NULLABLE\",\"name\":\"signature\",\"type\":\"STRING\"},{\"mode\":\"NULLABLE\",\"name\":\"msg_id\",\"type\":\"STRING\"},{\"mode\":\"NULLABLE\",\"name\":\"source\",\"type\":\"STRING\"}]"
  table_id = "events_raw"
}
resource "google_compute_network" "" {
  auto_create_subnetworks = true
  description             = "Default network for the project"
  name                    = "default"
  project                 = "fourkeys-000182"
  routing_mode            = "REGIONAL"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.150.0.0/20."
  dest_range  = "10.150.0.0/20"
  name        = "default-route-088a6030d750e60b"
  network     = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project     = "fourkeys-000182"
}
resource "google_compute_firewall" "" {
  allow {
    ports    = ["3389"]
    protocol = "tcp"
  }
  description   = "Allow RDP from anywhere"
  direction     = "INGRESS"
  name          = "default-allow-rdp"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  priority      = 65534
  project       = "fourkeys-000182"
  source_ranges = ["0.0.0.0/0"]
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.166.0.0/20."
  dest_range  = "10.166.0.0/20"
  name        = "default-route-33efd7ce34eb5403"
  network     = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project     = "fourkeys-000182"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.142.0.0/20."
  dest_range  = "10.142.0.0/20"
  name        = "default-route-2fa5b0f95aec3b1e"
  network     = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project     = "fourkeys-000182"
}
resource "google_compute_firewall" "" {
  allow {
    protocol = "icmp"
  }
  description   = "Allow ICMP from anywhere"
  direction     = "INGRESS"
  name          = "default-allow-icmp"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  priority      = 65534
  project       = "fourkeys-000182"
  source_ranges = ["0.0.0.0/0"]
}
resource "google_bigquery_table" "" {
  dataset_id = "four_keys"
  labels {
    managed-by-cnrm = "true"
  }
  project  = "fourkeys-000182"
  schema   = "[{\"mode\":\"NULLABLE\",\"name\":\"source\",\"type\":\"STRING\"},{\"mode\":\"NULLABLE\",\"name\":\"incident_id\",\"type\":\"STRING\"},{\"mode\":\"NULLABLE\",\"name\":\"time_created\",\"type\":\"TIMESTAMP\"},{\"mode\":\"NULLABLE\",\"name\":\"time_resolved\",\"type\":\"TIMESTAMP\"},{\"mode\":\"REPEATED\",\"name\":\"changes\",\"type\":\"STRING\"}]"
  table_id = "incidents"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.184.0.0/20."
  dest_range  = "10.184.0.0/20"
  name        = "default-route-0abd826fae9eefc2"
  network     = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project     = "fourkeys-000182"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.138.0.0/20."
  dest_range  = "10.138.0.0/20"
  name        = "default-route-19a9ab0a30f5db63"
  network     = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project     = "fourkeys-000182"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.164.0.0/20."
  dest_range  = "10.164.0.0/20"
  name        = "default-route-1aba036d4599f772"
  network     = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project     = "fourkeys-000182"
}
resource "google_compute_route" "" {
  description      = "Default route to the Internet."
  dest_range       = "0.0.0.0/0"
  name             = "default-route-5efd10c8e4cd974f"
  network          = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  next_hop_gateway = "https://www.googleapis.com/compute/beta/projects/fourkeys-000182/global/gateways/default-internet-gateway"
  priority         = 1000
  project          = "fourkeys-000182"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.182.0.0/20."
  dest_range  = "10.182.0.0/20"
  name        = "default-route-59206d91b86a1b7d"
  network     = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project     = "fourkeys-000182"
}
resource "google_compute_firewall" "" {
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }
  description   = "Allow SSH from anywhere"
  direction     = "INGRESS"
  name          = "default-allow-ssh"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  priority      = 65534
  project       = "fourkeys-000182"
  source_ranges = ["0.0.0.0/0"]
}
resource "google_compute_firewall" "" {
  allow {
    ports    = ["0-65535"]
    protocol = "tcp"
  }
  allow {
    ports    = ["0-65535"]
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
  description   = "Allow internal traffic on the default network"
  direction     = "INGRESS"
  name          = "default-allow-internal"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  priority      = 65534
  project       = "fourkeys-000182"
  source_ranges = ["10.128.0.0/9"]
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.128.0.0/20."
  dest_range  = "10.128.0.0/20"
  name        = "default-route-6e1f6377bf89ad70"
  network     = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project     = "fourkeys-000182"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.154.0.0/20."
  dest_range  = "10.154.0.0/20"
  name        = "default-route-9b4b5d1b28d620e8"
  network     = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project     = "fourkeys-000182"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.132.0.0/20."
  dest_range  = "10.132.0.0/20"
  name        = "default-route-9912a29220aa414d"
  network     = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project     = "fourkeys-000182"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.172.0.0/20."
  dest_range  = "10.172.0.0/20"
  name        = "default-route-56c1d0c13f8e80d2"
  network     = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project     = "fourkeys-000182"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.170.0.0/20."
  dest_range  = "10.170.0.0/20"
  name        = "default-route-6fcc7c7d31ca5ead"
  network     = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project     = "fourkeys-000182"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.168.0.0/20."
  dest_range  = "10.168.0.0/20"
  name        = "default-route-3fd05711a2c08aa5"
  network     = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project     = "fourkeys-000182"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.148.0.0/20."
  dest_range  = "10.148.0.0/20"
  name        = "default-route-4205a2564827731d"
  network     = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project     = "fourkeys-000182"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.156.0.0/20."
  dest_range  = "10.156.0.0/20"
  name        = "default-route-379c03f08ee95f55"
  network     = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project     = "fourkeys-000182"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.170.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project       = "fourkeys-000182"
  purpose       = "PRIVATE"
  region        = "asia-east2"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.174.0.0/20."
  dest_range  = "10.174.0.0/20"
  name        = "default-route-bdc8f351fd7e1a32"
  network     = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project     = "fourkeys-000182"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.174.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project       = "fourkeys-000182"
  purpose       = "PRIVATE"
  region        = "asia-northeast2"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.160.0.0/20."
  dest_range  = "10.160.0.0/20"
  name        = "default-route-ca9430d606ed20f6"
  network     = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project     = "fourkeys-000182"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.152.0.0/20."
  dest_range  = "10.152.0.0/20"
  name        = "default-route-86bd1844cc466b23"
  network     = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project     = "fourkeys-000182"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.146.0.0/20."
  dest_range  = "10.146.0.0/20"
  name        = "default-route-97baa9a017d13f8b"
  network     = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project     = "fourkeys-000182"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.184.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project       = "fourkeys-000182"
  purpose       = "PRIVATE"
  region        = "asia-southeast2"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.178.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project       = "fourkeys-000182"
  purpose       = "PRIVATE"
  region        = "asia-northeast3"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.146.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project       = "fourkeys-000182"
  purpose       = "PRIVATE"
  region        = "asia-northeast1"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.152.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project       = "fourkeys-000182"
  purpose       = "PRIVATE"
  region        = "australia-southeast1"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.180.0.0/20."
  dest_range  = "10.180.0.0/20"
  name        = "default-route-d8d93ba31274a275"
  network     = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project     = "fourkeys-000182"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.162.0.0/20."
  dest_range  = "10.162.0.0/20"
  name        = "default-route-84228326083bff93"
  network     = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project     = "fourkeys-000182"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.138.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project       = "fourkeys-000182"
  purpose       = "PRIVATE"
  region        = "us-west1"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.172.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project       = "fourkeys-000182"
  purpose       = "PRIVATE"
  region        = "europe-west6"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.168.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project       = "fourkeys-000182"
  purpose       = "PRIVATE"
  region        = "us-west2"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.132.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project       = "fourkeys-000182"
  purpose       = "PRIVATE"
  region        = "europe-west1"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.150.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project       = "fourkeys-000182"
  purpose       = "PRIVATE"
  region        = "us-east4"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.140.0.0/20."
  dest_range  = "10.140.0.0/20"
  name        = "default-route-a5838e0b6056b0df"
  network     = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project     = "fourkeys-000182"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.156.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project       = "fourkeys-000182"
  purpose       = "PRIVATE"
  region        = "europe-west3"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.158.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project       = "fourkeys-000182"
  purpose       = "PRIVATE"
  region        = "southamerica-east1"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.142.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project       = "fourkeys-000182"
  purpose       = "PRIVATE"
  region        = "us-east1"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.128.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project       = "fourkeys-000182"
  purpose       = "PRIVATE"
  region        = "us-central1"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.160.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project       = "fourkeys-000182"
  purpose       = "PRIVATE"
  region        = "asia-south1"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.158.0.0/20."
  dest_range  = "10.158.0.0/20"
  name        = "default-route-c1c750c144d34c75"
  network     = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project     = "fourkeys-000182"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.164.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project       = "fourkeys-000182"
  purpose       = "PRIVATE"
  region        = "europe-west4"
}
resource "google_pubsub_subscription" "" {
  ack_deadline_seconds = 10
  expiration_policy {
    ttl = "2678400s"
  }
  labels {
    managed-by-cnrm = "true"
  }
  message_retention_duration = "604800s"
  name                       = "CloudBuildSubscription"
  project                    = "fourkeys-000182"
  push_config {
    oidc_token {
      service_account_email = "cloud-run-pubsub-invoker@fourkeys-000182.iam.gserviceaccount.com"
    }
    push_endpoint = "https://cloud-build-worker-453rs347fa-uc.a.run.app"
  }
  topic = "projects/fourkeys-000182/topics/cloud-builds"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.140.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project       = "fourkeys-000182"
  purpose       = "PRIVATE"
  region        = "asia-east1"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.166.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project       = "fourkeys-000182"
  purpose       = "PRIVATE"
  region        = "europe-north1"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.148.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project       = "fourkeys-000182"
  purpose       = "PRIVATE"
  region        = "asia-southeast1"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.178.0.0/20."
  dest_range  = "10.178.0.0/20"
  name        = "default-route-cfd6014ce0b2d47d"
  network     = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project     = "fourkeys-000182"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.180.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project       = "fourkeys-000182"
  purpose       = "PRIVATE"
  region        = "us-west3"
}
resource "google_pubsub_subscription" "" {
  ack_deadline_seconds = 10
  expiration_policy {
    ttl = "2678400s"
  }
  labels {
    managed-by-cnrm = "true"
  }
  message_retention_duration = "604800s"
  name                       = "GithubSubscription"
  project                    = "fourkeys-000182"
  push_config {
    oidc_token {
      service_account_email = "cloud-run-pubsub-invoker@fourkeys-000182.iam.gserviceaccount.com"
    }
    push_endpoint = "https://github-worker-453rs347fa-uc.a.run.app"
  }
  topic = "projects/fourkeys-000182/topics/GitHub-Hookshot"
}
resource "google_service_account" "" {
  account_id   = "528445800720-compute"
  display_name = "Compute Engine default service account"
  project      = "fourkeys-000182"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.182.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project       = "fourkeys-000182"
  purpose       = "PRIVATE"
  region        = "us-west4"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.162.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project       = "fourkeys-000182"
  purpose       = "PRIVATE"
  region        = "northamerica-northeast1"
}
resource "google_service_account" "" {
  account_id   = "cloud-run-pubsub-invoker"
  display_name = "Cloud Run Pub/Sub Invoker"
  project      = "fourkeys-000182"
}
resource "google_pubsub_topic" "" {
  labels {
    managed-by-cnrm = "true"
  }
  name    = "GitHub-Hookshot"
  project = "fourkeys-000182"
}
resource "google_pubsub_topic" "" {
  labels {
    managed-by-cnrm = "true"
  }
  name    = "cloud-builds"
  project = "fourkeys-000182"
}
resource "google_storage_bucket" "" {
  force_destroy = false
  labels {
    managed-by-cnrm = "true"
  }
  location      = "US"
  name          = "fourkeys-000182_cloudbuild"
  project       = "projects/528445800720"
  storage_class = "STANDARD"
}
resource "google_storage_bucket" "" {
  force_destroy = false
  labels {
    managed-by-cnrm = "true"
  }
  location      = "US"
  name          = "artifacts.fourkeys-000182.appspot.com"
  project       = "projects/528445800720"
  storage_class = "STANDARD"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.154.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/fourkeys-000182/global/networks/default"
  project       = "fourkeys-000182"
  purpose       = "PRIVATE"
  region        = "europe-west2"
}
