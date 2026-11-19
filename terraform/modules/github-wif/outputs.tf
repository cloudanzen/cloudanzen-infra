output "provider_name" {
  description = "Full provider resource name for google-github-actions/auth (workload_identity_provider)."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "service_account_emails" {
  description = "CI service account emails keyed by account ID."
  value       = { for k, sa in google_service_account.ci : k => sa.email }
}
