variable "project_id" {
  description = "Environment project for secrets, backups and service accounts. No default: must be explicit."
  type        = string
}

variable "cluster_project_id" {
  description = "Shared cluster project (ADR-0006); its workload identity pool is <id>.svc.id.goog."
  type        = string
}

variable "region" {
  description = "Region; also the backup bucket location. No default: must be explicit."
  type        = string
}
