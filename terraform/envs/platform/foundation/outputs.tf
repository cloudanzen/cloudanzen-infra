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
