variable "name" {}
variable "description" {}
variable "project_id" {}
variable "cloudbuild" {}
variable "owner" {}
variable "repository" {}
variable "branch" {}
variable "include" {
  type    = list(string)
  default = []
}
variable "substitutions" {
  type = map(string)
}
variable "invert_regex" {
  type    = bool
  default = false
}