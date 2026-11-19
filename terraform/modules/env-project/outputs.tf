output "eso_service_account_email" {
  description = "GCP service account for this namespace's ESO SecretStore."
  value       = google_service_account.eso.email
}

output "db_backup_service_account_email" {
  description = "GCP service account for CloudNativePG backups."
  value       = google_service_account.db_backup.email
}

output "db_backup_bucket" {
  description = "Backup bucket name."
  value       = google_storage_bucket.db_backups.name
}

output "secret_ids" {
  description = "Created secret containers (names only)."
  value       = [for s in google_secret_manager_secret.this : s.secret_id]
}
