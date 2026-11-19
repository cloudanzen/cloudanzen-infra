variable "org_id" {
  description = "GCP organization ID. Supplied as an HCP workspace variable; not committed (public repository)."
  type        = string
}

variable "billing_account" {
  description = "Billing account ID. Supplied as an HCP workspace variable; not committed."
  type        = string
}

variable "environment_projects" {
  description = "Per-environment projects (ADR-0006). Project IDs are global; change them if taken."
  type = map(object({
    project_id = string
    name       = string
  }))
  default = {
    staging = { project_id = "cloudanzen-staging", name = "CloudAnzen staging" }
    prod    = { project_id = "cloudanzen-prod", name = "CloudAnzen production" }
  }
}

variable "plan_service_account_email" {
  description = "HCP Terraform plan identity; granted read-only access to the new projects."
  type        = string
  default     = "terraform-plan@cloudanzen-gke.iam.gserviceaccount.com"
}
