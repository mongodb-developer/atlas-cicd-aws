module "aws_vpc" {
  source            = "../../modules/aws/vpc"
  region            = var.region
  project_name      = var.project_name
}
module "aws_pipeline" {
  source            = "../../modules/aws/code-pipeline"
  project_name      = var.project_name
  region            = lower(var.region)
  environment_name  = var.environment_name
  org_api_pub_key   = var.org_api_pub_key
  org_api_pri_key   = var.org_api_pri_key
  org_id            = var.org_id
  depends_on        = [module.aws_vpc]
}

