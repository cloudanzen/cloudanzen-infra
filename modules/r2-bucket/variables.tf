variable "account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "bucket_name" {
  description = "Name of the R2 bucket"
  type        = string
}

variable "location" {
  description = "R2 bucket location hint"
  type        = string
  default     = "ENAM" # Eastern North America
}

variable "r2_permission_group_ids" {
  description = "Permission group IDs for R2 read/write access"
  type        = list(string)
  default     = []
}
