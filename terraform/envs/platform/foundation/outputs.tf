output "cluster_name" {
  description = "Shared cluster name."
  value       = module.cluster.name
}

output "cluster_workload_pool" {
  description = "Pass to the environment roots as cluster_workload_pool."
  value       = module.cluster.workload_identity_pool
}

output "registry_url" {
  description = "Docker repository URL prefix for CI."
  value       = module.registry.repository_url
}

output "github_workload_identity_provider" {
  description = "Value for google-github-actions/auth workload_identity_provider."
  value       = module.github_wif.provider_name
}

output "ci_service_accounts" {
  description = "CI service account emails."
  value       = module.github_wif.service_account_emails
}

output "nat_ip_addresses" {
  description = "Static egress addresses to publish for customer allowlisting."
  value       = module.network.nat_ip_addresses
}

output "gateway_address" {
  description = "Shared Gateway IPv4 address; environment roots point their DNS records here."
  value       = google_compute_global_address.gateway.address
}

output "gateway_address_name" {
  description = "Global address name the Gateway references (spec.addresses NamedAddress)."
  value       = google_compute_global_address.gateway.name
}

output "gateway_certificate_map" {
  description = "Certificate map name the Gateway references (networking.gke.io/certmap)."
  value       = google_certificate_manager_certificate_map.gateway.name
}

output "gateway_ssl_policy" {
  description = "SSL policy name the Gateway references (GCPGatewayPolicy)."
  value       = google_compute_ssl_policy.gateway.name
}
