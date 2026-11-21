variable "cluster_project_id" {
  description = "Shared cluster project that owns the Gateway, its address and certificate map (ADR-0006)."
  type        = string
}

variable "environment" {
  description = "Environment name, used in resource names (staging or prod)."
  type        = string
}

variable "zone_name" {
  description = "Cloudflare zone that holds the records, e.g. cloudanzen.com."
  type        = string
}

variable "base_domain" {
  description = "Environment domain under the zone, e.g. staging.cloudanzen.com. The certificate covers *.<base_domain>."
  type        = string
}

variable "hostnames" {
  description = "Labels under base_domain that get an A record to the Gateway, e.g. [\"app\", \"api\", \"platform\"]."
  type        = list(string)
}

variable "gateway_address_name" {
  description = "Global address the Gateway uses (owned by the platform foundation root)."
  type        = string
  default     = "cloudanzen-gateway"
}

variable "certificate_map" {
  description = "Certificate map the Gateway uses (owned by the platform foundation root)."
  type        = string
  default     = "cloudanzen-gateway"
}

variable "labels" {
  description = "Labels for Google resources."
  type        = map(string)
  default     = {}
}
