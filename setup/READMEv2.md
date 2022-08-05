# Installation guide
This guide describes how to set up Four Keys with your GitHub or GitLab project. The main steps are:

1. Forking this repository
1. Enabling services on your Google Cloud project
1. Providing values for required Terraform variables
1. Executing Terraform to deploy resources
1. Generating sample data (optional)
1. Integrating your repository to send data to your Four Keys deployment.

> Alternatively, to deploy Four Keys as a remote Terraform module, see `terraform/modules/fourkeys/README.md`
----
# Before you begin

To deploy Four Keys with Terraform, you will first need:
> TODO: list specific permissions instead of OWNER
* A Google Cloud project with billing enabled
* The owner role assigned to you on the project
* The [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) and [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) installed on your local machine. We recommend deploying from [Cloud Shell](https://shell.cloud.google.com/?show=ide%2Cterminal) on your Google Cloud project.

## Enable required services

Fourkeys uses the following Google Cloud APIs:
* [BigQuery](https://console.cloud.google.com/apis/library/bigquery.googleapis.com)
* [Cloud Build](https://console.cloud.google.com/apis/library/cloudbuild.googleapis.com)
* [Cloud Run](https://console.cloud.google.com/apis/library/run.googleapis.com)
* [Secret Manager](https://console.cloud.google.com/apis/library/secretmanager.googleapis.com)

Enable them on your project use the gcloud CLI:

```sh
gcloud services enable bigquery.googleapis.com cloudbuild.googleapis.com run.googleapis.com secretmanager.googleapis.com
```

----
# Deploying with Terraform

## Prepare the code

1. Clone or fork the Four Keys git repository and change your current working directory to `terraform/example`

    ```sh
    git clone https://github.com/GoogleCloudPlatform/fourkeys.git &&
    cd fourkeys/terraform/example
    ```
    The `example` directory has a `main.tf` file that deploys Four Keys' resources via a single Terraform module. The parameters are populated by the variables declared in `variables.tf`.  

2. Rename `terraform.tfvars.example` to `terraform.tfvars` 
3. Edit in values for the required variables. To accept the default value of a variable indicated in `variables.tf`, exclude it from `terraform.tfvars`

## Initialize and apply the Terraform

1. Initialize the Terraform:
    ```sh
    terraform init
    ```
1.  Before applying the Terraform, preview changes and catch any errors in your configuration:
    
    ```sh
    terraform plan
    ```
1. Deploy the resources to your Google Cloud Project:
    ```sh
    terraform apply
    ```
Once complete, your Four Keys infrastructure is in-place to receive and process events.

----
# Generating mock data

To test your Four Keys deployment, you can generate mock data that simulates events from a Github repository.  

1. Export your event handler URL to an environment variable. This is the webhook URL that will receive events:

    ```sh
    export WEBHOOK=`gcloud run services list --project=<PROJECT_ID> --format 'value(status.url)' --filter=metadata.name:event-handler`
    ```

1. Export your event handler secret to an environment variable. This is the secret used to authenticate events sent to the webhook:

    ```sh
    export SECRET=`gcloud secrets versions access --project=<PROJECT_ID> --secret=event-handler 1`
    
    ``` 

1. From the root of the fourkeys project run:

    ```sh
    python3 data_generator/generate-data.py --vc_system=github
    ```

    The data generated will run through the pipeline that the Terraform provisioned:
    * The event handler logs show successful requests
    * The Pub/Sub topic show messages posted
    * The BigQuery GitHub parser show successful requests

1. View the generated data in the `events_raw` table in with bq:

    ```sh
    bq query 'SELECT * FROM four_keys.events_raw WHERE source = "githubmock";'
    ```

    Or query the table directly in [BigQuery](https://console.cloud.google.com/bigquery):

    ```sql
    SELECT * FROM four_keys.events_raw WHERE source = 'githubmock';
    ```

----