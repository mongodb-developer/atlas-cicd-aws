variable "org_id" {
  sensitive = true
}
variable "org_api_pub_key" {
  sensitive = true
}
variable "org_api_pri_key" {
}
variable "db_username"{
    type = string
    default = "demon"
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
variable "pubKey_dev" {
    default =""
}
variable "privKey_dev" {
    default =""
}
variable "projId_dev" {
    default =""
}
variable "pubKey_test" {
    default =""
}
variable "privKey_test" {
    default =""
}
variable "projId_test" {
    default =""
}
variable "pubKey_prod" {
    default =""
}
variable "privKey_prod" {
    default =""
}
variable "projId_prod" {
    default =""
}
variable db_role {
    default ="atlasAdmin"
}