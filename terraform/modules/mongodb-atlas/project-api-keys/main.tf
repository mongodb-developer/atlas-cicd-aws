terraform {
  required_providers {
    mongodbatlas = {
      source = "mongodb/mongodbatlas"
      version = "0.8.2"
    }
  }
}

# Create a Atlas projects with API keys and users
resource "mongodbatlas_project" "my_project_dev" {
  name   = join("-",[var.project_name,"dev",var.region,"project"])
  org_id = var.org_id
}
# Create a Atlas projects with API keys and users
resource "mongodbatlas_project" "my_project_test" {
  name   = join("-",[var.project_name,"test",var.region,"project"])
  org_id = var.org_id
}
# Create a Atlas projects with API keys and users
resource "mongodbatlas_project" "my_project_prod" {
  name   = join("-",[var.project_name,"prod",var.region,"project"])
  org_id = var.org_id
}
resource "null_resource" "create-api-keys" {
  triggers = {
    org_id = var.org_id
    org_api_pub_key = var.org_api_pub_key
    org_api_pri_key = var.org_api_pri_key
    project_name = var.project_name
  }

  provisioner "local-exec" {
      command = <<EOT
      myJsonDev=$(curl --user "${var.org_api_pub_key}:${var.org_api_pri_key}" --digest --header "Accept: application/json" --header "Content-Type: application/json" --request POST "https://cloud.mongodb.com/api/atlas/v1.0/groups/${mongodbatlas_project.my_project_dev.id}/apiKeys?pretty=true" --data '{ "desc" : "${var.project_name}-dev", "roles": ["GROUP_OWNER","GROUP_CLUSTER_MANAGER"]}');
      myJsonTest=$(curl --user "${var.org_api_pub_key}:${var.org_api_pri_key}" --digest --header "Accept: application/json" --header "Content-Type: application/json" --request POST "https://cloud.mongodb.com/api/atlas/v1.0/groups/${mongodbatlas_project.my_project_test.id}/apiKeys?pretty=true" --data '{ "desc" : "${var.project_name}-test", "roles": ["GROUP_OWNER","GROUP_CLUSTER_MANAGER"]}');
      myJsonProd=$(curl --user "${var.org_api_pub_key}:${var.org_api_pri_key}" --digest --header "Accept: application/json" --header "Content-Type: application/json" --request POST "https://cloud.mongodb.com/api/atlas/v1.0/groups/${mongodbatlas_project.my_project_prod.id}/apiKeys?pretty=true" --data '{ "desc" : "${var.project_name}-prod", "roles": ["GROUP_OWNER","GROUP_CLUSTER_MANAGER"]}');
      sleep 20;
      
      pubKey=$(echo "$myJson" | jq  -r .publicKey)
      privKey=$(echo "$myJson" | jq  -r .privateKey)
      projId="${mongodbatlas_project.my_project_dev.id}"
      pubKey_dev=$(echo "$myJsonDev" | jq  -r .publicKey)
      privKey_dev=$(echo "$myJsonDev" | jq  -r .privateKey)
      projId_dev="${mongodbatlas_project.my_project_dev.id}"
      pubKey_test=$(echo "$myJsonTest" | jq  -r .publicKey)
      privKey_test=$(echo "$myJsonTest" | jq  -r .privateKey)
      projId_test="${mongodbatlas_project.my_project_test.id}"
      pubKey_prod=$(echo "$myJsonProd" | jq  -r .publicKey)
      privKey_prod=$(echo "$myJsonProd" | jq  -r .privateKey)
      projId_prod="${mongodbatlas_project.my_project_prod.id}"

      echo "{\"pubKey\":\"$pubKey\",\"privKey\":\"$privKey\",\"projId\":\"$projId\",\"pubKey_dev\":\"$pubKey_dev\",\"privKey_dev\":\"$privKey_dev\",\"projId_dev\":\"$projId_dev\", \"pubKey_test\":\"$pubKey_test\",\"privKey_test\":\"$privKey_test\",\"projId_test\":\"$projId_test\", \"pubKey_prod\":\"$pubKey_prod\",\"privKey_prod\":\"$privKey_prod\",\"projId_prod\":\"$projId_prod\"}" > terraform.json
      
      env;
      
EOT
    }
  provisioner "local-exec" {
      when    = destroy
      command = <<EOT
      for id in $(curl --user "${self.triggers.org_api_pub_key}:${self.triggers.org_api_pri_key}" --digest \
      --header "Accept: application/json" \
      --request GET "https://cloud.mongodb.com/api/public/v1.0/orgs/${self.triggers.org_id}/apiKeys?pretty=true" | jq -r '.results[] | select(.desc| startswith("${self.triggers.project_name}")).id'
      ); do
        echo $id
        curl --user "${self.triggers.org_api_pub_key}:${self.triggers.org_api_pri_key}" --digest \
      --header "Accept: application/json" \
      --header "Content-Type: application/json" \
      --request DELETE "https://cloud.mongodb.com/api/public/v1.0/orgs/${self.triggers.org_id}/apiKeys/$id?pretty=true"
      done            
EOT
      on_failure = continue
    }

    depends_on = [mongodbatlas_project.my_project_dev,mongodbatlas_project.my_project_test,mongodbatlas_project.my_project_prod ]
}


