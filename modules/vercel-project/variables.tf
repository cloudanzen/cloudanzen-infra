variable "project_name" {
  description = "Vercel project name"
  type        = string
}

variable "framework" {
  description = "Framework (nextjs or vite)"
  type        = string
  default     = "vite"
}

variable "git_repo" {
  description = "GitHub repository (owner/name)"
  type        = string
}

variable "build_command" {
  description = "Build command"
  type        = string
  default     = "npm run build"
}

variable "output_directory" {
  description = "Build output directory"
  type        = string
  default     = "dist"
}

variable "domains" {
  description = "Custom domains to attach"
  type        = list(string)
  default     = []
}

variable "env_vars" {
  description = "Environment variables"
  type = map(object({
    value  = string
    target = optional(list(string), ["production", "preview"])
  }))
  default = {}
}
