terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# The run's short-lived GCP identity (HCP dynamic credentials) authenticates
# to the cluster; no kubeconfig or static token exists.
data "google_client_config" "current" {}

data "google_container_cluster" "this" {
  name     = var.cluster_name
  location = var.region
  project  = var.project_id
}

locals {
  cluster_host = "https://${data.google_container_cluster.this.endpoint}"
  cluster_ca   = base64decode(data.google_container_cluster.this.master_auth[0].cluster_ca_certificate)
}

provider "kubernetes" {
  host                   = local.cluster_host
  token                  = data.google_client_config.current.access_token
  cluster_ca_certificate = local.cluster_ca
}

provider "helm" {
  kubernetes = {
    host                   = local.cluster_host
    token                  = data.google_client_config.current.access_token
    cluster_ca_certificate = local.cluster_ca
  }
}
