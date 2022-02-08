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
module "main" {
  source            = "../../main/aws-resources/"
  org_id            = var.org_id
  org_api_pri_key   = var.org_api_pri_key
  org_api_pub_key   = var.org_api_pub_key
  environment_name  = var.environment_name
  project_name      = var.project_name
  region            = var.region
  master_branch     = var.master_branch
}
module "project-api-keys" {
  source            = "../../modules/mongodb-atlas/project-api-keys/"
  org_id            = var.org_id
  org_api_pri_key   = var.org_api_pri_key
  org_api_pub_key   = var.org_api_pub_key
  environment_name  = "dev"
  project_name      = var.project_name
  region            = var.region
}
data "local_file" "api-secrets" {
    filename = "terraform.json"
    depends_on        =[module.project-api-keys]
}
locals { 
  json_data = jsondecode(data.local_file.api-secrets.content)
  privateKey_dev = local.json_data.privKey_dev
  publicKey_dev = local.json_data.pubKey_dev
  projId_dev  = local.json_data.projId_dev

  privateKey_test = local.json_data.privKey_test
  publicKey_test = local.json_data.pubKey_test
  projId_test  = local.json_data.projId_test
  privateKey_prod = local.json_data.privKey_prod
  publicKey_prod = local.json_data.pubKey_prod
  projId_prod  = local.json_data.projId_prod

}

module "project-secret_dev" {
  source            = "../../modules/aws/project-secret/"
  org_id            = var.org_id
  org_api_pri_key   = var.org_api_pri_key
  org_api_pub_key   = var.org_api_pub_key
  environment_name  = "dev"
  project_name      = var.project_name
  privKey           = local.privateKey_dev
  pubKey            = local.publicKey_dev
  projId            = local.projId_dev
  region            = var.region
  depends_on        =[data.local_file.api-secrets]
}


module "project-secret_test" {
  source            = "../../modules/aws/project-secret/"
  org_id            = var.org_id
  org_api_pri_key   = var.org_api_pri_key
  org_api_pub_key   = var.org_api_pub_key
  environment_name  = "test"
  project_name      = var.project_name
  privKey           = local.privateKey_test
  pubKey            = local.publicKey_test
  projId            = local.projId_test
  region            = var.region
  depends_on        =[data.local_file.api-secrets]
}



module "project-secret_prod" {
  source            = "../../modules/aws/project-secret/"
  org_id            = var.org_id
  org_api_pri_key   = var.org_api_pri_key
  org_api_pub_key   = var.org_api_pub_key
  environment_name  = "prod"
  project_name      = var.project_name
  privKey           = local.privateKey_prod
  pubKey            = local.publicKey_prod
  projId            = local.projId_prod
  region            = var.region
  depends_on        =[data.local_file.api-secrets]
}

module "cluster-users_dev" {
  source            = "../../modules/mongodb-atlas/cluster-users"
  environment_name  = "dev"
  project_id        = local.projId_dev
  db_username       = var.db_username
  db_role           = var.db_role
  region            = var.region
  project_name      = var.project_name
}

resource "aws_ssm_parameter" "database_password_dev" {
  name  = join("-",[var.project_name,"dbpassword",var.region,"dev"])
  type  = "SecureString"
  value = module.cluster-users_dev.db_password
}
resource "aws_ssm_parameter" "database_username_dev" {
  name  = join("-",[var.project_name,"dbusername",var.region,"dev"])
  type  = "SecureString"
  value = var.db_username
}

module "cluster-users_test" {
  source            = "../../modules/mongodb-atlas/cluster-users"
  environment_name  = "test"
  project_id        = local.projId_test
  db_username       = var.db_username
  db_role           = var.db_role
  region            = var.region
  project_name      = var.project_name
}

resource "aws_ssm_parameter" "database_password_test" {
  name  = join("-",[var.project_name,"dbpassword",var.region,"test"])
  type  = "SecureString"
  value = module.cluster-users_test.db_password
}
resource "aws_ssm_parameter" "database_username_test" {
  name  = join("-",[var.project_name,"dbusername",var.region,"test"])
  type  = "SecureString"
  value = var.db_username
}

module "cluster-users_prod" {
  source            = "../../modules/mongodb-atlas/cluster-users"
  environment_name  = "prod"
  project_id        = local.projId_prod
  db_username       = var.db_username
  db_role           = var.db_role
  region            = var.region
  project_name      = var.project_name
}

resource "aws_ssm_parameter" "database_password_prod" {
  name  = join("-",[var.project_name,"dbpassword",var.region,"prod"])
  type  = "SecureString"
  value = module.cluster-users_prod.db_password
}
resource "aws_ssm_parameter" "database_username_prod" {
  name  = join("-",[var.project_name,"dbusername",var.region,"prod"])
  type  = "SecureString"
  value = var.db_username
}

