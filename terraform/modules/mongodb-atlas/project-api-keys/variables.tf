variable "org_id" {}
variable "org_api_pub_key" {
  sensitive = true
}
variable "org_api_pri_key" {
  sensitive = true
}
variable "project_name" {}
variable "region" {}
variable "environment_name" {}

variable "pubKey" {
    default =""
}
variable "privKey" {
    default =""
}
variable "projId" {
    default =""
}