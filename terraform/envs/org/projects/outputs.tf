output "project_ids" {
  description = "Environment project IDs keyed by environment."
  value       = { for k, p in google_project.env : k => p.project_id }
}
