variable "org_id" {
  sensitive = true
}
variable "org_api_pub_key" {
  sensitive = true
}
variable "org_api_pri_key" {
}
variable "project_name" {}
variable "environment_name" {}
variable "region" {}
variable "master_branch" {
  type        = string
  default     = "main"
}

variable "pubKey" {
    default =""
}
variable "privKey" {
    default =""
}
variable "projId" {
    default =""
}