variable "project_id" {
  description = "Project that hosts the pool and CI service accounts."
  type        = string
}

variable "github_owner" {
  description = "GitHub organization allowed to federate."
  type        = string
  default     = "cloudanzen"
}

variable "pool_id" {
  description = "Workload identity pool ID."
  type        = string
  default     = "github"
}

variable "provider_id" {
  description = "Workload identity pool provider ID."
  type        = string
  default     = "github-oidc"
}

variable "identities" {
  description = "CI service accounts keyed by account ID, with the owner/repo names allowed to impersonate each."
  type = map(object({
    description  = string
    repositories = list(string)
  }))

  validation {
    condition     = alltrue([for id in values(var.identities) : length(id.repositories) > 0])
    error_message = "Each CI identity needs at least one repository."
  }
}
