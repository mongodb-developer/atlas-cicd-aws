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

data "aws_ssm_parameter" "project_id" {
  name = join("-",[var.project_name,"project-id",var.region,var.environment_name])
}
module "cluster" {
  source            = "../../modules/mongodb-atlas/cluster"
  project_id        = data.aws_ssm_parameter.project_id.value
  project_name      = var.project_name
  cluster_size      = var.cluster_size
  cluster_disk_size_gb = var.cluster_disk_size_gb
  cluster_mongodbversion = var.cluster_mongodbversion
  region            = var.region
  environment_name  = var.environment_name
}



module "aws_privatelink" {
  source            = "../../modules/aws/privatelink"
  project_id        = data.aws_ssm_parameter.project_id.value
  project_name      = var.project_name
  region            = var.region      
}