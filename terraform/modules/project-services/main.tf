# Enables the Google APIs a project needs. APIs are never disabled on
# destroy: other resources (or other roots) may still depend on them.
resource "google_project_service" "this" {
  for_each = toset(var.services)

  project                    = var.project_id
  service                    = each.value
  disable_on_destroy         = false
  disable_dependent_services = false
}
