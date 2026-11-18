variable "project_id" {
  description = "Shared cluster project (ADR-0006), e.g. cloudanzen-gke. No default: must be explicit."
  type        = string
}

variable "region" {
  description = "Region for the cluster, network and registry. No default: must be explicit."
  type        = string
}

variable "github_owner" {
  description = "GitHub organization allowed to federate."
  type        = string
  default     = "cloudanzen"
}

variable "nat_ip_count" {
  description = "Reserved static egress addresses."
  type        = number
  default     = 2
}

variable "master_authorized_cidrs" {
  description = "Control-plane allowlist; set once the bootstrap executor is chosen (ADR-0002)."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}
