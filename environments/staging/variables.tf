variable "railway_token" {
  description = "Railway API token"
  type        = string
  sensitive   = true
}

variable "vercel_token" {
  description = "Vercel API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for cloudanzen.com"
  type        = string
}

variable "sentry_dsn_backend" {
  description = "Sentry DSN for backend"
  type        = string
  sensitive   = true
  default     = ""
}

variable "sentry_dsn_frontend" {
  description = "Sentry DSN for frontend"
  type        = string
  sensitive   = true
  default     = ""
}
