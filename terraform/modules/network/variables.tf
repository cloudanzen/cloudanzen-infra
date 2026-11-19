variable "project_id" {
  description = "Project that owns the network (the shared cluster project)."
  type        = string
}

variable "name" {
  description = "Network name prefix."
  type        = string
  default     = "cloudanzen"
}

variable "region" {
  description = "Region for the subnet, router and NAT."
  type        = string
}

variable "nodes_cidr" {
  description = "Primary range for nodes."
  type        = string
  default     = "10.10.0.0/20"
}

variable "pods_cidr" {
  description = "Secondary range for pods."
  type        = string
  default     = "10.20.0.0/14"
}

variable "services_cidr" {
  description = "Secondary range for services."
  type        = string
  default     = "10.30.0.0/20"
}

variable "nat_ip_count" {
  description = "Number of reserved static NAT egress addresses."
  type        = number
  default     = 2

  validation {
    condition     = var.nat_ip_count >= 1
    error_message = "At least one static NAT address is required."
  }
}
