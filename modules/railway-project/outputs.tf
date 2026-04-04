output "project_id" {
  description = "Railway project ID"
  value       = railway_project.this.id
}

output "service_ids" {
  description = "Map of service name to service ID"
  value       = { for k, v in railway_service.services : k => v.id }
}
