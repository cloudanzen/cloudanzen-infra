# VPC for the shared GKE cluster, with Cloud NAT on reserved static
# addresses. The addresses are published so customers can allowlist
# CloudAnzen for integrations (see plan section 3). Staging and production
# share them while they share the cluster (ADR-0006).

resource "google_compute_network" "this" {
  project                 = var.project_id
  name                    = var.name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "nodes" {
  project                  = var.project_id
  name                     = "${var.name}-${var.region}"
  region                   = var.region
  network                  = google_compute_network.this.id
  ip_cidr_range            = var.nodes_cidr
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }
}

resource "google_compute_router" "this" {
  project = var.project_id
  name    = "${var.name}-router"
  region  = var.region
  network = google_compute_network.this.id
}

resource "google_compute_address" "nat" {
  count = var.nat_ip_count

  project      = var.project_id
  name         = "${var.name}-nat-${count.index}"
  region       = var.region
  address_type = "EXTERNAL"

  lifecycle {
    # Customers allowlist these addresses; losing one breaks integrations.
    prevent_destroy = true
  }
}

resource "google_compute_router_nat" "this" {
  project                            = var.project_id
  name                               = "${var.name}-nat"
  router                             = google_compute_router.this.name
  region                             = var.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = google_compute_address.nat[*].self_link
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
