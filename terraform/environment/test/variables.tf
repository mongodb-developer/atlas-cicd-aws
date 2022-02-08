variable "cluster_size" {
  type = string
  description = "Cluster size name, M2/M5/M10"
  default = "M10" // Could be M2/M5/M10...etc
}
variable "cluster_mongodbversion" {
  description = "The Major MongoDB Version"
  default = "4.4"
}
variable "cluster_disk_size_gb" {
  description = "MongoDB Disk Size"
  default = "100"
}

variable "region" {
  description = "MongoDB Atlas Cluster Region"
  default = "EU-WEST-1"
}
variable "environment_name" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
variable "org_id" {
  description = "Organisation Id"
  type        = string
}
variable "org_api_pri_key" {
  description = "Organization API Private Key"
  type        = string
}
variable "org_api_pub_key" {
  description = "Organization API Pub Key"
  type        = string
}
variable "db_role" {
  description = "Database role"
  type        = string
  default     = "atlasAdmin"
}
variable "db_username" {
  description = "Database user"
  type        = string
  default     = "myUser"
}
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "my-cluster"
}
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
