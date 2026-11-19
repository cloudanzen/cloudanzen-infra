variable "project_id" {
  description = "Project that hosts the registry."
  type        = string
}

variable "region" {
  description = "Registry location."
  type        = string
}

variable "repository_id" {
  description = "Repository name."
  type        = string
  default     = "cloudanzen"
}

variable "keep_recent_versions" {
  description = "Most recent versions per image always kept."
  type        = number
  default     = 30
}

variable "labels" {
  description = "Resource labels."
  type        = map(string)
  default     = {}
}
