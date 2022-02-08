terraform {
  required_providers {
    mongodbatlas = {
      source = "mongodb/mongodbatlas"
      version = "0.8.2"
    }
  }
}

resource "random_password" "database_password" {
  length  = 16
  special = false
}

resource "mongodbatlas_database_user" "my_user" {
  username           = join("-",[var.project_name,var.db_username,var.environment_name]) 
  password           = random_password.database_password.result
  project_id         = var.project_id
  auth_database_name = "admin"
  roles {
    role_name     = var.db_role
    database_name = "admin"
  }
}
