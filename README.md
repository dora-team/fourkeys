# Four Keys README 


# Background

Through six years of research, the [DevOps Research and Assessment (DORA)](https://cloud.google.com/blog/products/devops-sre/the-2019-accelerate-state-of-devops-elite-performance-productivity-and-scaling) team has identified four key metrics that indicate the performance of a software development team.  This project allows you to collect your data and compiles it into a dashboard displaying these key metrics. 



*   **Deployment Frequency**
*   **Lead Time for Changes**
*   **Time to Restore Services**
*   **Change Failure Rate**


# How it works



1.  Events are sent to a webhook target hosted on Cloud Run
1.  The Cloud Run target publishes all events to Pub/Sub
1.  A Cloud Run instance is subscribed to the topics and does some light data transformation and inputs the data into BigQuery
1.  Nightly scripts are scheduled in BigQuery to complete the data transformations and feed into the dashboard


![FourKeys Design](images/fourkeys-design.png)


# Code Structure


* bq_workers/
  * Contains the code for the individual bigquery workers.  Each data source has its own worker service with the logic for parsing the data from the pub/sub message. Eg: Github has its own worker which only looks at events pushed to the Github-Hookshot pub/sub topic
* data_generator/
  * Contains a python script for generating mock github data
* event_handler/
  * Contains the code for the event_handler. This is the public service that accepts incoming webhooks.  
* setup/
  * Contains the code for setting up and tearing down the fourkeys pipeline. Also contains a script for extending the data sources.
* shared/
  * Contains a shared module for inserting data into bigquery, which is used by the bq_workers


# How to Use 


## Out of the box

_The project currently uses python3 and supports data extraction for Cloud Build and GitHub events._



1.  Fork this project
1.  Run the automation scripts, which will do the following (See the [INSTALL.md](setup/INSTALL.md) for more details):
    1.  Set up a new Google Cloud Project
    1.  Create and deploy the Cloud Run webhook target and ETL workers
    1.  Create the Pub/Sub topics and subscriptions
    1.  Enable the Google Secret Manager and create a secret for your Github repo
    1.  Create a BigQuery dataset and tables, and schedule the nightly scripts
    1.  Open up a browser tab to connect your data to a DataStudio dashboard template
1.  Set up your development environment to send events to the webhook created in the second step
    1.  Add the secret to your github webhook


## How to generate mock data


The setup script includes an option to generate mock data.  The data generator creates mocked github events, which will be ingested into the table with the source “githubmock.”   It creates following events: 

* 5 mock commits with timestamps no earlier than a week ago
  * _Note: Number can be adjusted_
* 1 associated deployment
* Associated mock incidents 
  * _Note: By default, less than 15% of deployments will create a mock incident. Threshold can be adjusted in the script._

To run outside of the setup script, ensure that you’ve saved your webhook URL and Github Secret in your environment variables:

```sh
export WEBHOOK={your event handler URL}
export GITHUB_SECRET={your github signing secret}
```

Then run the following command:

```sh
python data_generator/data.py
```

You will see events being run through the pipeline:
*  The event handler logs will show successful requests
*  The PubSub topic will show messages posted
*  The bigquery github parser will show successful requests
*  You will be able to query the events_raw table directly in bigquery:


```sql
SELECT * FROM four_keys.events_raw WHERE source = 'githubmock';
```


## How to reclassify events

Currently the scripts consider some events to be “changes”, “deploys”, and “incidents.”   If you want to reclassify one of the events in the table (eg, you use a different label for your incidents other than “incident”), no changes are required on the architecture or code of the project.  Simply update the nightly scripts in BigQuery for the following tables:



*   four\_keys.changes
*   four\_keys.deployments
*   four\_keys.incidents


## How to extend to other event sources



1.  Add to the `AUTHORIZED_SOURCES` in `sources.py`
    1.  If you want to create a verification function, add the function to the file as well
1.  Run the `new_source.sh` script in the `setup` directory. This script will create a PubSub topic, a PubSub subscription, and the new service using the `new_source_template` 
    1.  Update the main.py in the new service to parse the data properly
1.  Update the BigQuery Script to classify the data properly

**If you add a common data source, please submit a pull request so that others may benefit from the functionality.**


## How  to run tests
This project uses nox to manage tests.  Ensure that nox is installed:

```sh
pip install nox
```

The noxfile defines what tests will run on the project.  Currently, it’s set up to run all the pytest files in all the directories, as well as run a linter on all directories.   To run nox:

```sh
python -m nox
```

### To list tests

To list all the test sesssions in the noxfile:

```sh
python -m nox -l
```

### To run a specific test

Once you have the list of test sessions, you can run a specific session with:

```sh
python -m nox -s "{name_of_session}" 
```

The "name_of_session" will be something like "py-3.6(folder='.....').  

# Data Schema


### four\_keys.events\_raw


<table>
  <tr>
   <td><strong>Field Name</strong>
   </td>
   <td><strong>Type</strong>
   </td>
   <td><strong>Notes</strong>
   </td>
  </tr>
  <tr>
   <td>source
   </td>
   <td>STRING
   </td>
   <td>eg: github
   </td>
  </tr>
  <tr>
   <td>event_type
   </td>
   <td>STRING
   </td>
   <td>eg: push
   </td>
  </tr>
  <tr>
   <td>🔑id
   </td>
   <td>STRING
   </td>
   <td>Id of the development object. Eg, bug id, commit id, PR id
   </td>
  </tr>
  <tr>
   <td>metadata
   </td>
   <td>JSON
   </td>
   <td>Body of the event
   </td>
  </tr>
  <tr>
   <td>time_created
   </td>
   <td>TIMESTAMP
   </td>
   <td>The time the event was created
   </td>
  </tr>
  <tr>
   <td>signature
   </td>
   <td>STRING
   </td>
   <td>Encrypted signature key from the event. This will be the <strong>unique key</strong> for the table.  
   </td>
  </tr>
  <tr>
   <td>msg_id
   </td>
   <td>STRING
   </td>
   <td>Message id from Pub/Sub
   </td>
  </tr>
</table>


This table will be used to create the following three derived tables: 


#### four\_keys.deployments 

_Note: Deployments and changes have a many to one relationship.  Table only contains successful deployments._


<table>
  <tr>
   <td><strong>Field Name</strong>
   </td>
   <td><strong>Type</strong>
   </td>
   <td><strong>Notes</strong>
   </td>
  </tr>
  <tr>
   <td>🔑deploy_id
   </td>
   <td>string
   </td>
   <td>Id of the deployment - foreign key to id in events_raw
   </td>
  </tr>
  <tr>
   <td>changes
   </td>
   <td>array of strings
   </td>
   <td>List of id’s associated with the deployment. Eg: commit_id’s, bug_id’s, etc.  
   </td>
  </tr>
  <tr>
   <td>time_created
   </td>
   <td>timestamp
   </td>
   <td>Time the deployment was completed
   </td>
  </tr>
</table>



#### four\_keys.changes


<table>
  <tr>
   <td><strong>Field Name</strong>
   </td>
   <td><strong>Type</strong>
   </td>
   <td><strong>Notes</strong>
   </td>
  </tr>
  <tr>
   <td>🔑change_id
   </td>
   <td>string
   </td>
   <td>Id of the change - foreign key to id in events_raw
   </td>
  </tr>
  <tr>
   <td>time_created
   </td>
   <td>timestamp
   </td>
   <td>Time_created from events_raw
   </td>
  </tr>
  <tr>
   <td>change_type
   </td>
   <td>string
   </td>
   <td>The event type
   </td>
  </tr>
</table>



#### four\_keys.incidents


<table>
  <tr>
   <td><strong>Field Name</strong>
   </td>
   <td><strong>Type</strong>
   </td>
   <td><strong>Notes</strong>
   </td>
  </tr>
  <tr>
   <td>🔑incident_id
   </td>
   <td>string
   </td>
   <td>Id of the failure incident
   </td>
  </tr>
  <tr>
   <td>changes
   </td>
   <td>array of strings
   </td>
   <td>List of deployment ID’s that caused the failure
   </td>
  </tr>
  <tr>
   <td>time_created
   </td>
   <td>timestamp
   </td>
   <td>Min timestamp from changes
   </td>
  </tr>
  <tr>
   <td>time_resolved
   </td>
   <td>timestamp
   </td>
   <td>Time the incident was resolved
   </td>
  </tr>
</table>



# Dashboard 

The dashboard displays all four metrics with daily systems data, as well as a current snapshot of the last 90 days.  

To understand the metrics and intent of the dashboard, please see the [2019 State of DevOps Report.](https://services.google.com/fh/files/misc/state-of-devops-2019.pdf) 


## Metrics Definitions

**Deployment Frequency**



*   The number of deployments per time period: daily, weekly, monthly, yearly. 

**Lead Time for Changes**



*   The median amount of time for a commit to be deployed into production

**Time to Restore Services**



*   For a failure, the median amount of time between the deployment which caused the failure, and the restoration.  The restoration is measured by closing an associated bug / incident report. 

**Change Failure Rate**



*   The number of failures per the number of deployments.  Eg, if there are four deployments in a day and one causes a failure, that will be a 25% change failure rate.


## Color Coding

The color coding of the quarterly snapshots roughly follows the buckets set forth in the State of DevOps Report.  

**Deployment Frequency**



*   **Green:** Weekly
*   **Yellow:** Monthly
*   **Red:** Between once per month and once every 6 months.  
    *   This will be expressed as “Yearly.” 

**Lead Time to Change**



*   **Green:** Less than one week
*   **Yellow:** Between one week and one month
*   **Red:** Between one month and 6 months.  
*   **Red:** Anything greater than 6 months
    *   This will be expressed as “One year.” 

**Time to Restore Service**



*   **Green:** Less than one day
*   **Yellow:** Less than one week
*   **Red:**  Between one week and a month
    *   This will be expressed as “One month” 
*   **Red:** Anything greater than a month
    *   This will be expressed as “One year” 

**Change Failure Rate**



*   **Green:** Less than 15%
*   **Yellow:** 16% - 45%
*   **Red:**  Anything greater than 45%


![DORA Chart](images/dora-chart.png)

Disclaimer: This is not an officially supported Google product
