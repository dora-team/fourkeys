# Installation Guide

## Getting Started

Getting started using FourKeys is relatively simple.  You will need a few tools installed:
#### Requirements
- [GCloud SDK](https://cloud.google.com/sdk/install)

You will also need to be owner on a GCP project that has billing enabled.  You may either use this project to house the architecture for the Four Keys, or you will be given the option to create new projects.  If you create new projects, the original project will NOT be altered during set up, but the billing information from this parent project will be applied to any projects created.

Once you have your parent project just do the following from the top-level directory of this repository:
```bash
gcloud config set project $PARENT_PROJECT_ID
cd setup
./setup.sh 2>&1 | tee setup.log
```

#### Manual Prompts
The setup script will prompt you for the following input:

- Would you like to create a new Google Cloud Project for the four key metrics? (y/n)
  - If you choose no, you will be asked to input and confirm the ID of the project that you want to use.
- Are you using Gitlab? (y/n)
  - If you choose yes, the Gitlab specific Pub/Sub topic, subscriptions, and worker will be created.
- Are you using Github? (y/n)
  - If you choose yes, the Github specific Pub/Sub topic, subscriptions, and worker will be created.
- BigQuery setup
  - If you've never setup BigQuery before, a setup page will open in your browser.
- Would you like to create a separate new project to test deployments for the four key metrics? (y/n)
  - You have the option of creating a new project to test out doing deployments and seeing how they are tracked in the dashboard.  However, if you already have a project with deployments, you may select no to skip this step.  You do not need to select yes to generate mock data.
- Would you like to generate mock data? (y/n)
  - If you select yes, a script will run through and send mock Gitlab or Github events to your event-handler.  This will populate your dashboard with mock data.  The mock data will include the work "mock" in the source.

#### New Projects
If you've chosen to create new projects, after the script finishes you will have two new projects named in the env.sh file of the form 'fourkeys-XXXX' and 'helloworld-XXXXX'.  The fourkeys-XXXX project will be home to all the services that collect data from your deployments, while helloworld-XXXX will be the staging and prod deployments for your application.

Later if you want to remove the newly created projects and all associated data, you can run the cleanup.sh.  **Only do this when you are done experimenting with fourkeys entirely, or want to start over because cleanup.sh will remove the projects and all the collected data.**

## The Setup Explained
The setup script is going to do many things to help create the service architecture described in the README.md.  The script will output the commands you would need to do manually.

The steps are:
- Create randomly generated project names
- Save project names in env.sh
- Set up Four Keys Project
  - Create project
  - Link billing to parent project
  - Enable Apis
  - Add IAM Policy Bindings
  - Create PubSub Topics
  - Deploy Event Handler
  - Deploy BigQuery Github and/or Gitlab Worker
  - Deploy BigQuery Cloud Build Worker
  - Create BigQuery PubSub Subscriptions
  - Create BigQuery Dataset, Tables, and Scheduled Queries
- Set up Helloworld Project
  - Create Project
  - Link billing to parent project
  - Enable Apis
  - Deploy Helloworld to staging
  - Deploy Helloworld to prod
- Generate mock data using the scripts found in the data_generator/ directory
- Connect to the DataStudio Dashboard template
  - Select organization and project
  - Click "Create Report" on the next screen with the list of fields


## Integrate with a Live Repo

The setup script can create mock data, but it cannot integrate automatically with our live projects.  To measure our team's performance, we should hook up the services to a live repo with ongoing deployments so we can experiment with how changes, successful deployments, and failed deployments affect our statistics.

Doing this will require a few extra manual steps:

#### Collect Changes Data

##### Github instructions
- Start with your Github repo
  - If you're using the Helloworld sample, fork the demo by navigating to the [Github Repo](https://github.com/knative/docs.git) and clicking 'Fork'.
- Navigate to your repo (or forked repo) and click 'Settings.'
- Select 'Webhooks' from the left hand side.
- Click 'Add Webhook'
- Get the Event Handler endpoint for your Four Keys service:
```bash
. ./env.sh
gcloud config set project ${FOURKEYS_PROJECT}
gcloud run --platform managed --region ${FOURKEYS_REGION} services describe event-handler --format=yaml | grep url | head -1 | sed -e 's/  *url: //g'
```
- In the 'Add Webhook' interface use the Event Handler endpoint for 'Payload URL'
- Run the following command to get the secret from Google Secrets Manager
```bash
gcloud secrets versions access 1 --secret="github-secret"
```
- Put the secret in the box labelled 'Secret'
- Select 'application/json' for 'Content Type'
- Select 'Send me everything'
- Finish with clicking 'Add Webhook'

##### Gitlab instructions
- Navigate to your repo and click 'Settings.'
- Select `Webhooks` from the menu
- Get the Event Handler endpoint for your Four Keys service:
```bash
. ./env.sh
gcloud config set project ${FOURKEYS_PROJECT}
gcloud run --platform managed --region ${FOURKEYS_REGION} services describe event-handler --format=yaml | grep url | head -1 | sed -e 's/  *url: //g'
```
- Use the Event Handler endpoint for 'Payload URL'
- Run the following command to get the secret from Google Secrets Manager
```bash
gcloud secrets versions access 1 --secret="github-secret"
```
- Put the secret in the box labelled 'Secret Token'
- Select all the checkboxes
- Leave the `Enable SSL verification selected`
- Finish with clicking 'Add Webhook'

#### Collect Deployment Data

##### Configuring Cloud Build to deploy on GitHub PR merges
- Go back to your repo's main page
- At the top of the Github page, click 'Marketplace'
- Search for 'Cloud Build'
- Select 'Google Cloud Build'
- Click 'Set Up Plan'
- Click 'Set up with Google Cloud Build'
- Select 'Only select repositories'
- Fill in your forked repo
- Log in to Google Cloud Platform
- Add your new FourKeys project named fourkeys-XXXXX
- Select your repo
- Click 'Connect repository'
- Click 'Create push trigger'

And now, whenever a pull request is merged into master of your fork, Cloud Build will trigger a deploy into prod and data will flow into your Four Keys project.

##### Configuring Cloud Build to deploy on Gitlab merges
- Go to your fourkeys project and [create a service account](https://cloud.google.com/iam/docs/creating-managing-service-accounts#iam-service-accounts-create-console) called `gitlab-deploy`
- [Create a JSON service account key](https://cloud.google.com/iam/docs/creating-managing-service-account-keys#iam-service-account-keys-create-console) for your `gitlab-deploy` service account
- In your Gitlab Repo, navigate to `Settings` on the left-hand menu and then select `CI/CD`
- Save your account key under variables.
  - Input SERVICE_ACCOUNT in the `key` field.
  - Input the JSON in the `Value` field. 
  - Select `Protect variable`
- Save your Google Cloud project-id under variables
 - Input `PROJECT_ID` in the `key` field
 - Input your project-id in the `value` field
- Add a `.gitlab-ci.yml` file to your repo
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

This will trigger a deployment on any `push` to the `master` branch.

#### Collect Incident Data

For this demo, we're using Gitlab and/or Github issues to track incidents.  

##### To create an incident

- Open an issue
- Add the tag `Incident`
- In the body of the issue, input `root cause: {SHA of the commit}`

When the incident is resolved, simply close the issue. The incident will be measured from the time of the deployment, to the resolution of the issue.  
