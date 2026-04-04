variable "project_name" {
  description = "Railway project name"
  type        = string
}

variable "environment" {
  description = "Environment name (staging or production)"
  type        = string
}

variable "services" {
  description = "Map of service names to their configuration"
  type = map(object({
    start_command    = optional(string, "npm run start:safe")
    healthcheck_path = optional(string, "/health")
    num_replicas     = optional(number, 1)
  }))
}

variable "env_vars" {
  description = "Environment variables for all services (non-secret)"
  type        = map(string)
  default     = {}
}
