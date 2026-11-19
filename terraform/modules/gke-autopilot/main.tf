# One shared GKE Autopilot cluster (ADR-0006). Staging and production run
# in separate namespaces; workload identity is always on in Autopilot.

resource "google_container_cluster" "this" {
  project  = var.project_id
  name     = var.name
  location = var.region

  enable_autopilot = true

  network    = var.network_id
  subnetwork = var.subnetwork_id

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
  }

  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_cidrs) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_cidrs
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  release_channel {
    channel = var.release_channel
  }

  maintenance_policy {
    recurring_window {
      start_time = var.maintenance_start_time
      end_time   = var.maintenance_end_time
      recurrence = var.maintenance_recurrence
    }
  }

  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }

  resource_labels = var.labels

  deletion_protection = true
}
