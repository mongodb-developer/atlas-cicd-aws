variable "project_name" {
  type        = string
  default     = "my-cluster"
}
variable "environment_name" {
  type        = string
}
variable "master_branch" {
  type        = string
  default     = "main"
}
variable "region" {
  type        = string
  default     = "eu-west-1"
}
variable "org_api_pub_key" {
  type    = string
  sensitive = true
}
variable "org_api_pri_key" {
  type    = string
  sensitive = true
}

variable "org_id" {
  type    = string
  sensitive = true
}