/**
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  cluster_type = "simple-zonal"
}

provider "google" {
  version = "~> 3.14.0"
  region  = var.region
}

module "gcp-network" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 2.0"
  project_id   = var.project_id
  network_name = var.network

  subnets = [
    {
      subnet_name   = var.subnetwork
      subnet_ip     = "10.0.0.0/17"
      subnet_region = var.region
    },
  ]

  secondary_ranges = {
    "${var.subnetwork}" = [
      {
        range_name    = var.ip_range_pods_name
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = var.ip_range_services_name
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}


module "gke" {
  source              = "terraform-google-modules/kubernetes-engine/google"
  project_id          = var.project_id
  name                = var.cluster_name
  regional            = true 
  region              = var.region
  network             = module.gcp-network.network_name
  subnetwork          = module.gcp-network.subnets_names[0]
  ip_range_pods       = var.ip_range_pods_name
  ip_range_services   = var.ip_range_services_name
  service_account     = "create"
  node_pools = [
    {
      name            = "default-node-pool"
      machine_type    = "n1-standard-4"
      remove_default_node_pool = true
    },
]
}

data "google_client_config" "default" {
}
