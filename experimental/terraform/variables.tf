variable "parent_project_id" {
  default = "stanke-fourkeys-testing" # TODO: remove this before merging
}

# Creating this variable but leaving it empty means that the user will be
# prompted for a value when terraform is run
variable "billing_account" {
  type        = string
  description = "The name of your billing account. Case-sensitive."
}