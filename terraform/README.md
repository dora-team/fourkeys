# Four Keys Terraform

This directory contains modules and examples for deploying Four Keys with Terraform. The primary module `modules/fourkeys` uses the other sub-modules to deploy resources to a provided Google Cloud Project.  

## Usage
See `examples` directory for examples. Simple usage:

```hcl
module "fourkeys" {
  source    = "github.com/GoogleCloudPlatform/fourkeys//terraform/modules/fourkeys"
  project_id = "your-google-cloud-project-id"
  parsers   = ['github']
}
```
The example above will deploy Four Keys with a Github parser for Github events.

## Deploying with Terraform


## Generating mock data

