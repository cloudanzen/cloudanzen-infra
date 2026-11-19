output "network_id" {
  description = "VPC ID."
  value       = google_compute_network.this.id
}

output "subnetwork_id" {
  description = "Node subnet ID."
  value       = google_compute_subnetwork.nodes.id
}

output "pods_range_name" {
  description = "Secondary range name for pods."
  value       = "pods"
}

output "services_range_name" {
  description = "Secondary range name for services."
  value       = "services"
}

output "nat_ip_addresses" {
  description = "Static egress addresses to publish for customer allowlisting."
  value       = google_compute_address.nat[*].address
}
