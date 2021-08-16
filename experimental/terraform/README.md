# Experimental Terraform setup

This folder contains terraform scripts to provision all of the infrastructure in a Four Keys GCP project.

**DO NOT USE!** This isn't ready for production yet (though it's close!)

## How to use

1. run `setup.sh`; this will:

- create a project for Four Keys
- purge all terraform state [useful during tf development]
- build containers using Cloud Build
- create a `terraform.tfvars` file
- invoke terraform

1. run the following commands to retrieve values needed for your SCM:

- ```
  echo `terraform output -raw event_handler_endpoint`
  echo `terraform output -raw event_handler_secret`
  ```

Current functionality:

- Create a GCP project (outside of terraform)
- Build the event-handler container image and push to GCR [TODO: use AR instead]
- Deploy the event-handler container as a Cloud Run service
- Emit the event-handler endpoint as an output
- Create and store webhook secret
- Create pubsub
- Set up BigQuery
- Build and deploy bigquery workers
- Emit the secret as an output
- Establish BigQuery scheduled queries
- Generate test data
- Launch Data Studio connector flow
- Support using an existing project
- Allow user to choose whether to generate test data

Open questions:

- Should we create a service account and run TF as that, or keep the current process of using application default credentials of the user who invokes the script?

Answered questions:

- What's an elegant way to support those user inputs (VCS, CI/CD) as conditionals in the TF? (see implementation: generate a list of parsers to create)
- Should we create the GCP project in terraform? No. The auth gets really complicated, especially when considering that the project may or may not be in an organization and/or folder

**Following is Nando's specific!** WIP

## Set Up

We recommend the use of [tfenv](https://github.com/tfutils/tfenv) to install and use the version defined in the code.

### Terraform Service Account

This code is set up to use a terraform service account with the least privileges to create the resources needed, therefore you will need to create one in your project (TODO: move to setup.sh):

```
gcloud init  # To select existing email and project

# The follow unset command clear any old credentials that may get in the way of impersonation
unset GOOGLE_OAUTH_ACCESS_TOKEN
unset GOOGLE_APPLICATION_CREDENTIALS
unset GOOGLE_CREDENTIALS

gcloud auth application-default login  # login as you to allow service account impersonation.
PROJECT_ID=$(gcloud config get-value project)
TF_SA_NAME=terraform
gcloud iam service-accounts create ${TF_SA_NAME} \
  --description "Infrastructure Provisioner" \
  --display-name "Terraform"
# grant service account permission to view Admin Project & Manage Cloud Storage
for ROLE in 'viewer' 'storage.admin' 'cloudbuild.builds.builder' 'artifactregistry.admin' 'bigquery.dataEditor' 'bigquery.jobUser' 'containerregistry.ServiceAgent' 'dns.admin' 'iam.serviceAccountCreator' 'iam.serviceAccountDeleter' 'iam.serviceAccountUser' 'pubsub.admin' 'resourcemanager.projectIamAdmin' 'run.admin' 'secretmanager.admin' 'serviceusage.apiKeysAdmin'; do
  gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member serviceAccount:${TF_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
    --role roles/${ROLE}
done

for API in 'cloudbuild.googleapis.com' 'cloudresourcemanager.googleapis.com' 'iamcredentials.googleapis.com' 'artifactregistry.googleapis.com' 'bigquery.googleapis.com' 'bigquerydatatransfer.googleapis.com' 'containerregistry.googleapis.com' 'dns.googleapis.com' 'iam.googleapis.com' 'run.googleapis.com' 'secretmanager.googleapis.com' 'serviceusage.googleapis.com'; do
  gcloud services enable "${API}"
done
```

#### Terraform Files

You will need to create a backend in an environment folder (experimental/terraform):

```
PROJECT_REGION=europe-west2
cat > backend.tf <<EOF
terraform {
  required_version = ">= 1.0"

  backend "gcs" {
    bucket = "${PROJECT_ID}-${PROJECT_REGION}-state"
    prefix = "fourkeys"
  }
}

EOF
```

You will need to create a project specific input file in an environment folder (experimental/terraform) and adjust to your needs:

```
cat > environment.auto.tfvars <<EOF

bigquery_region = "EU"
cloud_build_branch = "release"
google_project_id = "${PROJECT_ID}"
google_region = "${PROJECT_REGION}"
google_gcr_domain = "gcr.io"
google_domain_mapping_region = "europe-west1"
mapped_domain = "dora.nandos.ninja"
parsers = [ "cloud-build", "github" ]
owner = "NandosUK"
repository = "fourkeys"

EOF
```

Create the storage bucket:

```bash
# Create the terraform state storage bucket
export PROJECT_REGION=europe-west2
gsutil mb -p ${PROJECT_ID} -l ${PROJECT_REGION} gs://${PROJECT_ID}-${PROJECT_REGION}-state
gsutil versioning set on gs://${PROJECT_ID}-${PROJECT_REGION}-state
```

Now you can execute the standard Terraform commands from within an environment folder (experimental/terraform):

```
tfenv install 1.0.2
tfenv use 1.0.2

terraform init
terraform plan
terraform apply -auto-approve
terraform destroy -auto-approve
```
