# Per-environment project resources (ADR-0003, ADR-0006): Secret Manager
# secret containers (never versions/values), the CloudNativePG backup
# bucket, and the Google service accounts that the environment's
# Kubernetes service accounts impersonate. Workloads run in the shared
# cluster; IAM here keeps staging and production secrets and data apart.

locals {
  ksa_member = "serviceAccount:${var.cluster_workload_pool}[${var.namespace}/%s]"
}

# ── Secret containers ───────────────────────────────────────────────────────
# Values are added out of band through the secret-seeding runbook, so no
# secret payload ever enters Terraform state or plans.
resource "google_secret_manager_secret" "this" {
  for_each = toset(var.secret_ids)

  project   = var.project_id
  secret_id = each.value
  labels    = merge(var.labels, { environment = var.environment })

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }
}

# ── External Secrets Operator reader ───────────────────────────────────────
resource "google_service_account" "eso" {
  project      = var.project_id
  account_id   = "eso-${var.environment}"
  display_name = "External Secrets reader (${var.environment})"
}

resource "google_service_account_iam_member" "eso_wi" {
  service_account_id = google_service_account.eso.name
  role               = "roles/iam.workloadIdentityUser"
  member             = format(local.ksa_member, var.eso_ksa_name)
}

resource "google_secret_manager_secret_iam_member" "eso_access" {
  for_each = google_secret_manager_secret.this

  project   = var.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.eso.email}"
}

# ── CloudNativePG backups ──────────────────────────────────────────────────
resource "google_storage_bucket" "db_backups" {
  project                     = var.project_id
  name                        = "${var.project_id}-db-backups"
  location                    = var.backup_location
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  labels                      = merge(var.labels, { environment = var.environment })

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      days_since_noncurrent_time = var.backup_noncurrent_retention_days
    }
    action {
      type = "Delete"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_service_account" "db_backup" {
  project      = var.project_id
  account_id   = "db-backup-${var.environment}"
  display_name = "CloudNativePG backups (${var.environment})"
}

resource "google_service_account_iam_member" "db_backup_wi" {
  service_account_id = google_service_account.db_backup.name
  role               = "roles/iam.workloadIdentityUser"
  member             = format(local.ksa_member, var.db_cluster_ksa_name)
}

resource "google_storage_bucket_iam_member" "db_backup_objects" {
  bucket = google_storage_bucket.db_backups.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.db_backup.email}"
}

# Barman Cloud checks the destination with storage.buckets.get before
# archiving WAL; objectAdmin does not include it. legacyBucketReader adds
# only buckets.get and objects.list on this bucket.
resource "google_storage_bucket_iam_member" "db_backup_bucket_read" {
  bucket = google_storage_bucket.db_backups.name
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${google_service_account.db_backup.email}"
}
