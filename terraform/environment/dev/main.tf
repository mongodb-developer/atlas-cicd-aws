terraform {
  required_providers {
    mongodbatlas = {
      source = "mongodb/mongodbatlas"
      version = "0.8.2"
    }
  }
  backend "s3" {
    encrypt = true
    bucket  = "mongo-atlas-templates"
    key     = "my-cluster-bootstrap-account.tfstate"
  }  
  
}
provider "mongodbatlas" {
  public_key  = var.org_api_pub_key
  private_key = var.org_api_pri_key
}

module "atlas-project" {
  source            = "../../main/mongodb-atlas-resources/"
  org_id            = var.org_id
  org_api_pri_key   = var.org_api_pri_key
  org_api_pub_key   = var.org_api_pub_key
  environment_name  = var.environment_name
  db_username       = var.db_username
  db_role           = var.db_role
  project_name      = var.project_name
  cluster_size      = var.cluster_size
  cluster_mongodbversion = var.cluster_mongodbversion
  cluster_disk_size_gb = var.cluster_disk_size_gb
  region            = var.region
  master_branch     = var.master_branch
}



