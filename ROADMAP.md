# Four Keys 2022 Roadmap

## Mission and Vision

Four Keys mission:

  Be the industry-standard reference implementation for the automated calculation of the [DORA](https://cloud.google.com/blog/products/devops-sre/the-2019-accelerate-state-of-devops-elite-performance-productivity-and-scaling) Four Key metrics.  

The vision for this is:

* All discussion of the DORA Four Key metrics center around the key data entities of Changes, Deployments, and Incidents
* Clear guidelines on how to instrument your systems to gain continuous insights and drive continuous improvement
* A rich set of tool integrations and data mappings
* Support for common deployment patterns

Non-goals:

* The DORA research includes predictive analytics, recommendations, and improvement strategies. The Four Keys dashboard will not provide these resources. It will simply be a reflection of an organization’s software delivery performance.
*  Four Keys does not intend to be a one-stop shop for all operational performance metrics. The focus of this project should always be on the predictive metrics identified by the DORA research. 

## Roadmap

* Short Term
  * Enriching the dashboard
    * [More data points](https://github.com/GoogleCloudPlatform/fourkeys/issues/77)
    * New data views for drilling down into the metrics
  * More native Terraform installation 
    * Currently, the setup is a mix of `gcloud` commands and Terraform configuration.  We will move away from `gcloud` commands and rely more on the declarative Terraform setup.
* Long Term
  * CloudEvents migration 
    * Migrate the `four_keys.events_raw` schema to [CloudEvents](https://github.com/cloudevents/spec) schema
    * Use the CloudEvents adapters to do the ETL rather than the current [workers](bq-workers/)
  * New Integrations
    * CI/CD Tools
      * [Jenkins](https://www.jenkins.io/)
      * [Teamcity](https://www.jetbrains.com/teamcity/)
      * [Spinnaker](https://spinnaker.io/)
      * [GitHub Actions](https://github.com/features/actions)
    * Bugs / Incident Management
      * [Jira](https://www.atlassian.com/software/jira)
      * [ServiceNow](https://docs.servicenow.com/bundle/london-it-service-management/page/product/incident-management/concept/incident-management-process.html)
      * [PagerDuty](https://www.pagerduty.com/)
      * [Google Forms](https://www.google.com/forms/about/)
    * Version Control System
      * [Bitbucket](https://bitbucket.org/product)
      * [GitHub Enterprise](https://github.com/enterprise)
      * [Gitea](https://gitea.io/en-us/)
  * Custom deployment events
    * Support for different [deployment patterns](https://github.com/GoogleCloudPlatform/fourkeys/issues/46), eg multiple change sets in a single deployment
    * Canary and Blue/Green deployments

