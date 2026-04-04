variable "repository" {
  description = "Repository name (without owner)"
  type        = string
}

variable "default_branch" {
  description = "Default branch name"
  type        = string
  default     = "main"
}

variable "required_status_checks" {
  description = "Required CI status check context names"
  type        = list(string)
  default     = []
}

variable "enable_auto_merge" {
  description = "Enable auto-merge on the repository"
  type        = bool
  default     = true
}

variable "delete_branch_on_merge" {
  description = "Delete branches after merge"
  type        = bool
  default     = true
}
