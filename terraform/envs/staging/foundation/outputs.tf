output "eso_service_account_email" {
  description = "Annotate this namespace's ESO Kubernetes service account with it."
  value       = module.env.eso_service_account_email
}

output "db_backup_service_account_email" {
  description = "Annotate the CloudNativePG cluster service account with it."
  value       = module.env.db_backup_service_account_email
}

output "db_backup_bucket" {
  description = "Barman backup destination bucket."
  value       = module.env.db_backup_bucket
}

output "secret_ids" {
  description = "Secret containers to seed (names only)."
  value       = module.env.secret_ids
}

output "hostnames" {
  description = "Public hostnames for this environment."
  value       = module.edge.hostnames
}
