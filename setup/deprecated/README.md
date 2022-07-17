# Installation guide

This guide describes how to set up Four Keys with your GitHub or GitLab project. The main steps are:

1.  [Running the setup script](#running-the-setup-script)
1.  Integrating with your GitHub or Git Lab repo by:
    1.  [Collecting changes data](#collecting-changes-data)
    1.  [Collecting deployment data](#collecting-deployment-data)
    1.  [Collecting incident data](#collecting-incident-data)

## Before you begin

1.  Install [GCloud SDK](https://cloud.google.com/sdk/install).
1.  You must be owner on a Google Cloud project that has billing enabled. You may either use this project to house the architecture for the Four Keys, or you will be given the option to create new projects. If you create new projects, the original Google Cloud project will NOT be altered during set up, but the billing information from this parent project will be applied to any projects created.

## Running the setup script

1.  Once you have your Google Cloud project, run the following setup script from the top-level directory of this repository:

    ```bash
    gcloud config set project $PARENT_PROJECT_ID
    cd setup
    ./setup.sh 2>&1 | tee setup.log
    ```

1.  Answer the setup script's questions:

    *   Would you like to create a new Google Cloud Project for the four key metrics? (y/n)
        * If you choose no, you will be asked to input and confirm the ID of the project that you want to use.
    *   Are you using GitLab? (y/n)
        *   If you choose yes, the GitLab specific Pub/Sub topic, subscriptions, and worker will be created.
    *   Are you using GitHub? (y/n)
        *   If you choose yes, the GitHub specific Pub/Sub topic, subscriptions, and worker will be created.
    *   BigQuery setup
        *   If you've never setup BigQuery before, a setup page will open in your browser.
    *   Would you like to create a separate new project to test deployments for the four key metrics? (y/n)
        *   You have the option of creating a new Google Cloud project to test out doing deployments and seeing how they are tracked in the dashboard.  However, if you already have a project with deployments, you may select no to skip this step.  You do not need to select yes to generate mock data.
    *   Would you like to generate mock data? (y/n)
        *   If you select yes, a script will run through and send mock GitLab or GitHub events to your event-handler.  This will populate your dashboard with mock data.  The mock data will include the work "mock" in the source. You can generate mock data without using the setup script. See [Generating mock data](../readme.md).

### New Google Cloud projects

If you've chosen to create new Google Cloud projects, after the script finishes you will have an `env.sh` file specifying two new project-id's in the form of `fourkeys-XXXX` and `helloworld-XXXXX`.  The `fourkeys-XXXX` project is home to all the services that collect data from your deployments, while `helloworld-XXXX` is the staging and prod deployments for your example application.

If you ever want to remove the newly created projects and all associated data, you can run `cleanup.sh`.  **Only do this when you are done experimenting with Four Keys entirely, or want to start over. Running `cleanup.sh` will remove the projects and all the collected data.**

If you want to bulk delete many projects that you've created via the setup script, all of which will be named `fourkeys-XXXX` and `helloworld-XXXXX`, pass a flag to the cleanup script: `./cleanup.sh -b`

### The setup explained

The setup script does many things to help create the service architecture described in the `README.md`.  The script will output the commands you would otherwise need to do manually.

The steps are:
- Create randomly generated project names
- Creates an `env.sh` and saves the project values in it
- Set up Four Keys project
  - Create project
  - Link billing to parent project
  - Enable APIs
  - Add IAM Policy Bindings
  - Create Pub/Sub Topics
  - Deploy Event Handler
  - Deploy BigQuery GitHub and/or GitLab Worker
  - Deploy BigQuery Cloud Build Worker
  - Create BigQuery Pub/Sub Subscriptions
  - Create BigQuery Dataset, Tables, and Scheduled Queries
- Set up Helloworld project
  - Create Google Cloud project
  - Link billing to parent project
  - Enable APIs
  - Deploy Helloworld to staging
  - Deploy Helloworld to prod
- Generate mock data using the scripts found in the `data-generator/` directory
- Connect to the DataStudio Dashboard template
  - Select organization and project
  - Click **Create Report** on the next screen with the list of fields


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
