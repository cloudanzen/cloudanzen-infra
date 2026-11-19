variable "project_id" {
  description = "Environment project (secrets, backups, service accounts)."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string

  validation {
    condition     = contains(["staging", "prod"], var.environment)
    error_message = "environment must be staging or prod."
  }
}

variable "namespace" {
  description = "Kubernetes namespace of this environment in the shared cluster."
  type        = string
}

variable "cluster_workload_pool" {
  description = "Workload identity pool of the shared cluster, <cluster-project>.svc.id.goog."
  type        = string
}

variable "secret_ids" {
  description = "Secret Manager secret IDs to create as empty containers."
  type        = list(string)
}

variable "eso_ksa_name" {
  description = "Kubernetes service account used by this namespace's ESO SecretStore."
  type        = string
  default     = "external-secrets-reader"
}

variable "db_cluster_ksa_name" {
  description = "Kubernetes service account of the CloudNativePG cluster (defaults to the cluster name)."
  type        = string
  default     = "cloudanzen-db"
}

variable "backup_location" {
  description = "Bucket location for database backups."
  type        = string
}

variable "backup_noncurrent_retention_days" {
  description = "Days to keep noncurrent backup object versions."
  type        = number
  default     = 30
}

variable "labels" {
  description = "Resource labels."
  type        = map(string)
  default     = {}
}
