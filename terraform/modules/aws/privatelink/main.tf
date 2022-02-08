terraform {
  required_providers {
    mongodbatlas = {
      source = "mongodb/mongodbatlas"
      version = "0.8.2"
    }
  }
}


data "aws_caller_identity" "current" {}

data "aws_vpc" "vpc_id" {
  tags = {
    Name = join("-",[var.project_name,"aws_vpc",var.region,"base"])
  }
}

resource "mongodbatlas_privatelink_endpoint" "atlaspl" {
  project_id    = var.project_id
  provider_name = "AWS"
  region        = lower(var.region)
}
 
data "aws_subnet" "subnet_A" {
  tags = {
    Name   = join("-",[var.project_name,"subnet_primary_az1_A",var.region,"base"])
  } 
}
data "aws_subnet" "subnet_B" {
  tags = {
    Name   = join("-",[var.project_name,"subnet_primary_az2_B",var.region,"base"])
  }
}
data "aws_security_group" "security_group_default" {
  tags = {
    Name   = join("-",[var.project_name,"security_group_default",var.region,"base"])
  }
}

resource "aws_vpc_endpoint" "ptfe_service" {
  vpc_id             = data.aws_vpc.vpc_id.id
  service_name       = mongodbatlas_privatelink_endpoint.atlaspl.endpoint_service_name
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [data.aws_subnet.subnet_A.id, data.aws_subnet.subnet_B.id]
  security_group_ids = [data.aws_security_group.security_group_default.id]
  depends_on = [data.aws_subnet.subnet_A,data.aws_subnet.subnet_B,data.aws_security_group.security_group_default]
}


resource "mongodbatlas_privatelink_endpoint_service" "atlaseplink" {
  project_id            = mongodbatlas_privatelink_endpoint.atlaspl.project_id
  private_link_id       = mongodbatlas_privatelink_endpoint.atlaspl.private_link_id
  endpoint_service_id = aws_vpc_endpoint.ptfe_service.id
  provider_name         = "AWS"
}