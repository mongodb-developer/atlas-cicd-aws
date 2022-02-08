terraform {
  required_providers {
    mongodbatlas = {
      source = "mongodb/mongodbatlas"
      version = "0.8.2"
    }
  }
}

#
# Create a Shared Tier Cluster
#
resource "mongodbatlas_cluster" "my_cluster" {
  project_id              = var.project_id
  name                    = join("-",[var.project_name,var.environment_name,"cluster"])

  # Provider Settings "block"
  provider_name = "AWS"

  # options: AWS AZURE GCP
  #backing_provider_name = "AWS"

  # options: M2/M5 atlas regions per cloud provider
  # GCP - CENTRAL_US SOUTH_AMERICA_EAST_1 WESTERN_EUROPE EASTERN_ASIA_PACIFIC NORTHEASTERN_ASIA_PACIFIC ASIA_SOUTH_1
  # AZURE - US_EAST_2 US_WEST CANADA_CENTRAL EUROPE_NORTH
  # AWS - US_EAST_1 US_WEST_2 EU_WEST_1 EU_CENTRAL_1 AP_SOUTH_1 AP_SOUTHEAST_1 AP_SOUTHEAST_2
  provider_region_name = upper(var.region)
  
  # options: M2 M5
  provider_instance_size_name = var.cluster_size

  # If select M2 must be 2, if M5 must be 5
  disk_size_gb                = var.cluster_disk_size_gb

  # Will not change till new version of MongoDB but must be included
  mongo_db_major_version = var.cluster_mongodbversion
  auto_scaling_disk_gb_enabled = "false"
}
