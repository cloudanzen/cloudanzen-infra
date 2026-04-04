terraform {
  required_providers {
    railway = {
      source  = "terraform-community/railway"
      version = "~> 0.4"
    }
  }
}

# Railway project — represents one environment (staging or production)
resource "railway_project" "this" {
  name = "${var.project_name}-${var.environment}"
}

# Services within the project
resource "railway_service" "services" {
  for_each   = var.services
  project_id = railway_project.this.id
  name       = each.key
}

# Environment variables applied to each service
resource "railway_variable" "env_vars" {
  for_each = {
    for pair in flatten([
      for svc_name, svc in railway_service.services : [
        for key, value in var.env_vars : {
          key        = "${svc_name}-${key}"
          service_id = svc.id
          name       = key
          value      = value
        }
      ]
    ]) : pair.key => pair
  }

  environment_id = railway_project.this.default_environment_id
  service_id     = each.value.service_id
  name           = each.value.name
  value          = each.value.value
}
