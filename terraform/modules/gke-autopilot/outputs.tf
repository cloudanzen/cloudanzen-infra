output "name" {
  description = "Cluster name."
  value       = google_container_cluster.this.name
}

output "endpoint" {
  description = "Control-plane endpoint."
  value       = google_container_cluster.this.endpoint
  sensitive   = true
}

output "workload_identity_pool" {
  description = "Workload identity pool used in Kubernetes service account principals."
  value       = "${var.project_id}.svc.id.goog"
}
