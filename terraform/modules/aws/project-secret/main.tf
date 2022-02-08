terraform {
  required_providers {
    mongodbatlas = {
      source = "mongodb/mongodbatlas"
      version = "0.8.2"
    }
  }  
}


resource "aws_ssm_parameter" "project_id" {
  name  = join("-",[var.project_name,"project-id",var.region,var.environment_name])
  type  = "SecureString"
  value = var.projId
}
resource "aws_ssm_parameter" "api_public_key" {
  name  = join("-",[var.project_name,"public-api-key",var.region,var.environment_name])
  type  = "SecureString"
  value = var.pubKey
}

resource "aws_ssm_parameter" "api_private_key" {
  name  = join("-",[var.project_name,"private-api-key",var.region,var.environment_name])
  type  = "SecureString"
  value = var.privKey 
}


