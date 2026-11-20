# Shared platform foundation (ADR-0001, ADR-0006): APIs, network with
# static NAT egress, one GKE Autopilot cluster, the image registry and
# keyless GitHub Actions federation for image publishing.

locals {
  labels = { component = "platform-foundation" }
}

module "services" {
  source     = "../../../modules/project-services"
  project_id = var.project_id
  services = [
    "artifactregistry.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
  ]
}

module "network" {
  source       = "../../../modules/network"
  project_id   = var.project_id
  region       = var.region
  nat_ip_count = var.nat_ip_count

  depends_on = [module.services]
}

module "cluster" {
  source                  = "../../../modules/gke-autopilot"
  project_id              = var.project_id
  region                  = var.region
  network_id              = module.network.network_id
  subnetwork_id           = module.network.subnetwork_id
  pods_range_name         = module.network.pods_range_name
  services_range_name     = module.network.services_range_name
  master_authorized_cidrs = var.master_authorized_cidrs
  labels                  = local.labels
}

module "registry" {
  source     = "../../../modules/artifact-registry"
  project_id = var.project_id
  region     = var.region
  labels     = local.labels

  depends_on = [module.services]
}

module "github_wif" {
  source       = "../../../modules/github-wif"
  project_id   = var.project_id
  github_owner = var.github_owner

  identities = {
    "ci-image-publisher" = {
      description  = "GitHub Actions image publishing"
      repositories = ["${var.github_owner}/Cloudanzen-backend", "${var.github_owner}/Cloudanzen-frontend"]
    }
  }

  depends_on = [module.services]
}

resource "google_artifact_registry_repository_iam_member" "image_publisher" {
  project    = var.project_id
  location   = var.region
  repository = module.registry.repository_id
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${module.github_wif.service_account_emails["ci-image-publisher"]}"
}

# Autopilot nodes run as the Compute Engine default service account (the
# cluster's node identity cannot be changed after creation). This
# organization does not grant that account any roles automatically, so give
# it only what nodes need: pulling images from this repository, and the GKE
# node role for logging, monitoring and metadata.
data "google_project" "this" {
  project_id = var.project_id
}

locals {
  node_service_account = "serviceAccount:${data.google_project.this.number}-compute@developer.gserviceaccount.com"
}

resource "google_artifact_registry_repository_iam_member" "node_image_pull" {
  project    = var.project_id
  location   = var.region
  repository = module.registry.repository_id
  role       = "roles/artifactregistry.reader"
  member     = local.node_service_account
}

resource "google_project_iam_member" "node_default_role" {
  project = var.project_id
  role    = "roles/container.defaultNodeServiceAccount"
  member  = local.node_service_account
}
