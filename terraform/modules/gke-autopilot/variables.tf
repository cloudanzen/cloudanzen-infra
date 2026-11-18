variable "project_id" {
  description = "Project that hosts the shared cluster."
  type        = string
}

variable "name" {
  description = "Cluster name."
  type        = string
  default     = "cloudanzen"
}

variable "region" {
  description = "Regional cluster location."
  type        = string
}

variable "network_id" {
  description = "VPC ID from the network module."
  type        = string
}

variable "subnetwork_id" {
  description = "Node subnet ID from the network module."
  type        = string
}

variable "pods_range_name" {
  description = "Secondary range name for pods."
  type        = string
}

variable "services_range_name" {
  description = "Secondary range name for services."
  type        = string
}

variable "master_authorized_cidrs" {
  description = "CIDRs allowed to reach the control plane. Empty leaves the public endpoint without an allowlist; the bootstrap executor decision (ADR-0002) must set this before production use."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "release_channel" {
  description = "GKE release channel."
  type        = string
  default     = "REGULAR"

  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "release_channel must be RAPID, REGULAR or STABLE."
  }
}

variable "maintenance_start_time" {
  description = "RFC 3339 start of the recurring maintenance window."
  type        = string
  default     = "2026-01-03T02:00:00Z"
}

variable "maintenance_end_time" {
  description = "RFC 3339 end of the recurring maintenance window."
  type        = string
  default     = "2026-01-03T08:00:00Z"
}

variable "maintenance_recurrence" {
  description = "RRULE for the maintenance window."
  type        = string
  default     = "FREQ=WEEKLY;BYDAY=SA"
}

variable "labels" {
  description = "Resource labels."
  type        = map(string)
  default     = {}
}
