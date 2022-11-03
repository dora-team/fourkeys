# Installation guide
This guide describes how to set up Four Keys with your GitHub or GitLab project. The main steps are:


1. Forking or cloning this repository
1. Building required images with Cloud Build
1. Providing values for required Terraform variables
1. Executing Terraform to deploy resources
1. Generating sample data (optional)
1. Integrating your repository to send data to your Four Keys deployment.

> Alternatively, to deploy Four Keys as a remote Terraform module, see `terraform/modules/fourkeys/README.md`
----
# Before you begin

To deploy Four Keys with Terraform, you will first need:

* A Google Cloud project with billing enabled
* The owner role assigned to you on the project
* The [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) and [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) installed on your local machine. We recommend deploying from [Cloud Shell](https://shell.cloud.google.com/?show=ide%2Cterminal) on your Google Cloud project.

You will also need to clone this repository to your local machine:

```sh
git clone https://github.com/GoogleCloudPlatform/fourkeys.git && cd fourkeys
```

----

# Build required container images

Four Keys deploys containerized applications on Cloud Run using corresponding container images for the dashboard, event handler, and each of the services that will connect to Four Keys. By default, Terraform will set up Cloud Run services referencing containers uploaded to your project's container registry with the default names indicated in these steps:

1. Set an environment variable indicating your Google Cloud project ID:
    ```sh
    export PROJECT_ID="YOUR_PROJECT_ID"
    ```
1. Build the container for the event handler:
    ```sh
    gcloud builds submit ./event-handler --tag=gcr.io/${PROJECT_ID}/event-handler --project $PROJECT_ID
    ```
1. Build the container for the dashboard:
    ```sh
    gcloud builds submit ./dashboard --tag=gcr.io/${PROJECT_ID}/fourkeys-grafana-dashboard --project $PROJECT_ID
    ```
1. Use Cloud Build to build and push containers to Google Container Registry for the parsers you plan to use. See the [`bq-workers`](../bq-workers/) for available options. GitHub for example:
   ```sh
   gcloud builds submit bq-workers --config=bq-workers/parsers.cloudbuild.yaml --project $PROJECT_ID --substitutions=_SERVICE=github
   ```

# Deploy with Terraform

1. Change your working directory to `terraform/example` and rename `terraform.tfvars.example` to `terraform.tfvars`
   ```
   cd terraform/example && mv terraform.tfvars.example terraform.tfvars
   ```

1. Edit `terraform.tfvars` with values for the required variables. See `variables.tf` for a list of the variables, along with their descriptions and default values. Values not defined in `terraform.tfvars` will use default values defined in `variables.tf`

1. Run the following commands from the `example` directory:

    `terraform init` to inialize Terraform and download the module

    `terraform plan` to preview changes.

    `terraform apply` to deploy the resources.

Once complete, your Four Keys infrastructure will be in-place to receive and process events.

# Generating mock data

To test your Four Keys deployment, you can generate mock data that simulates events from a GitHub repository.  

1. Export your event handler URL an environment variable. This is the webhook URL that will receive events:

    ```sh
    export WEBHOOK=`gcloud run services list | grep event-handler | awk '{print $4}'`
    ```

1. Export your event handler secret to an environment variable. This is the secret used to authenticate events sent to the webhook:

    ```sh
    export SECRET=`gcloud secrets versions access 1 --secret=event-handler`
    ```

1. From the root of the fourkeys project run:

    ```sh
    python3 data-generator/generate_data.py --vc_system=github
    ```

    You can see these events being run through the pipeline:
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
