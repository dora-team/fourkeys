# Installation guide
This guide describes how to set up Four Keys with your GitHub or GitLab project. The main steps are:


1. Forking or cloning this repository
1. Building required images with Cloud Build
1. Providing values for required Terraform variables
1. Executing Terraform to deploy resources
1. Generating sample data (optional)

> Alternatively, to deploy Four Keys as a remote Terraform module, see [`terraform/modules/fourkeys/README.md`](../terraform/modules/fourkeys/README.md)

## Before you begin

To deploy Four Keys with Terraform, you will first need:

* A Google Cloud project with billing enabled
* The owner role assigned to you on the project
* The [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) and [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) installed on your local machine. We recommend deploying from [Cloud Shell](https://shell.cloud.google.com/?show=ide%2Cterminal) on your Google Cloud project.

## Deploying with Terraform

1. Set an environment variable indicating your Google Cloud project ID:
    ```sh
    export PROJECT_ID="YOUR_PROJECT_ID"
    ```

1. Clone the fourkeys git repository and change into the root directory
   ```
   git clone https://github.com/GoogleCloudPlatform/fourkeys.git && cd fourkeys
   ```

1. Use Cloud Build to build and push containers to Google Container Registry for the dashboard, event-handler:
   ```
   gcloud builds submit dashboard --config=dashboard/cloudbuild.yaml --project $PROJECT_ID && \
   gcloud builds submit event-handler --config=event-handler/cloudbuild.yaml --project $PROJECT_ID
   ```

1. Use Cloud Build to build and push containers to Google Container Registry for the parsers you plan to use. See the [`bq-workers`](../bq-workers/) for available options. GitHub for example:
   ```
   gcloud builds submit bq-workers --config=bq-workers/parsers.cloudbuild.yaml --project $PROJECT_ID --substitutions=_SERVICE=github
   ```

1. Change your working directory to `terraform/example` and rename `terraform.tfvars.example` to `terraform.tfvars`
   ```
   cd terraform/example && mv terraform.tfvars.example terraform.tfvars
   ```

1. Edit `terraform.tfvars` with values for the required variables. See `variables.tf` for a list of the variables, along with their descriptions and default values. Values not defined in `terraform.tfvars` will use default values defined in `variables.tf`

1. Run the following commands from the `example` directory:

    `terraform init` to inialize Terraform and download the module

    `terraform plan` to preview changes.

    `terraform apply` to deploy the resources.

## Generating mock data

To test your Four Keys deployment, you can generate mock data that simulates events from a GitHub repository.  

1. Export your event handler URL an environment variable. This is the webhook URL that will receive events:

    ```sh
    export WEBHOOK=`gcloud run services list --project $PROJECT_ID | grep event-handler | awk '{print $4}'`
    ```

1. Export your event handler secret to an environment variable. This is the secret used to authenticate events sent to the webhook:

    ```sh
    export SECRET=`gcloud secrets versions access 1 --secret=event-handler --project $PROJECT_ID`
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
    bq query --project_id $PROJECT_ID 'SELECT * FROM four_keys.events_raw WHERE source = "githubmock";'
    ```

    Or query the table directly in [BigQuery](https://console.cloud.google.com/bigquery):

    ```sql
    SELECT * FROM four_keys.events_raw WHERE source = 'githubmock';
    ```

## Integrating with a live repo

The setup script can create mock data, but it cannot integrate automatically with live projects.  To measure your team's performance, you need to integrate to your live GitHub or GitLab repo that has ongoing deployments. You can then measure the four key metrics, and experiment with how changes, successful deployments, and failed deployments affect your metrics.

To integrate Four Keys with a live repo, you need to:

1.  [Collect changes data](#collecting-changes-data)
1.  [Collect deployment data](#collecting-deployment-data)
1.  [Collect incident data](#collecting-incident-data)

### Collecting changes data

#### GitHub instructions

1.  Start with your GitHub repo
    *  If you're using the `Helloworld` sample, fork the demo by navigating to the [GitHub Repo](https://github.com/knative/docs.git) and clicking **Fork**.
1.  Navigate to your repo (or forked repo) and click **Settings**.
1.  Select **Webhooks** from the left hand side.
1.  Click **Add Webhook**.
1.  Get the Event Handler endpoint for your Four Keys service:
    ```bash
    . ./env.sh
    gcloud config set project ${FOURKEYS_PROJECT}
    gcloud run services describe event-handler --platform managed --region ${FOURKEYS_REGION} --format=yaml | grep url | head -1 | sed -e 's/  *url: //g'
    ```
1.  In the **Add Webhook** interface use the Event Handler endpoint for **Payload URL**.
1.  Run the following command to get the secret from Google Secrets Manager:
    ```bash
    gcloud secrets versions access 1 --secret="event-handler"
    ```
1.  Put the secret in the box labelled **Secret**.
1.  For **Content Type**, select **application/json**.
1.  Select **Send me everything**.
1.  Click **Add Webhook**.

#### GitLab instructions

1.  Navigate to your repo and click **Settings**.
1.  Select **Webhooks** from the menu.
1.  Get the Event Handler endpoint for your Four Keys service by running the following:
    ```bash
    . ./env.sh
    gcloud config set project ${FOURKEYS_PROJECT}
    gcloud run services describe event-handler --platform managed --region ${FOURKEYS_REGION} --format=yaml | grep url | head -1 | sed -e 's/  *url: //g'
    ```
1.  For **Payload URL**, use the Event Handler endpoint.
1.  Run the following command to get the secret from Google Secrets Manager:
    ```bash
    gcloud secrets versions access 1 --secret="event-handler"
    ```
1.  Put the secret in the box labelled **Secret Token**.
1.  Select all the checkboxes.
1.  Leave the **Enable SSL verification** selected.
1.  Click **Add Webhook**.

### Collecting deployment data

#### Configuring Cloud Build to deploy on GitHub Pull Request merges

1.  Go back to your repo's main page.
1.  At the top of the GitHub page, click **Marketplace**.
1.  Search for **Cloud Build**.
1.  Select **Google Cloud Build**.
1.  Click **Set Up Plan**.
1.  Click **Set up with Google Cloud Build**.
1.  Select **Only select repositories**.
1.  Fill in your forked repo.
1.  Log in to Google Cloud Platform.
1.  Add your new Four Keys project named `fourkeys-XXXXX`.
1.  Select your repo.
1.  Click **Connect repository**.
1.  Click **Create push trigger**.

And now, whenever a pull request is merged into master of your fork, Cloud Build will trigger a deploy into prod and data will flow into your Four Keys project.

#### Configuring Cloud Build to deploy on GitLab merges

1.  Go to your Four Keys project and [create a service account](https://cloud.google.com/iam/docs/creating-managing-service-accounts#iam-service-accounts-create-console) called `gitlab-deploy`.
1.  [Create a JSON service account key](https://cloud.google.com/iam/docs/creating-managing-service-account-keys#iam-service-account-keys-create-console) for your `gitlab-deploy` service account.
1.  In your GitLab repo, navigate to `Settings` on the left-hand menu and then select `CI/CD`.
1.  Save your account key under variables.
    1.  In the **key** field, input `SERVICE_ACCOUNT`.
    1.  In the **Value** field, input the JSON . 
    1.  Select **Protect variable**.
1.  Save your Google Cloud project-id under variables.
    1.  In the **key** field, input `PROJECT_ID`.
    1.  In the **value** field, input your `project-id`.
1.  Add a `.gitlab-ci.yml` file to your repo.
    ```
    image: google/cloud-sdk:alpine

    deploy_production:
      stage: deploy
      environment: Production
      only:
      - master
      script:
      - echo $SERVICE_ACCOUNT > /tmp/$CI_PIPELINE_ID.json
      - gcloud auth activate-service-account --key-file /tmp/$CI_PIPELINE_ID.json
      - gcloud builds submit . --project $PROJECT_ID
      after_script:
      - rm /tmp/$CI_PIPELINE_ID.json
    ```

This setup will trigger a deployment on any `push` to the `master` branch.

### Collecting incident data

Four Keys uses GitLab and/or GitHub issues to track incidents.  

#### Creating an incident

1.  Open an issue.
1.  Add the tag `Incident`.
1.  In the body of the issue, input `root cause: {SHA of the commit}`.

When the incident is resolved, close the issue. Four Keys will measure the incident from the time of the deployment to when the issue is closed.
