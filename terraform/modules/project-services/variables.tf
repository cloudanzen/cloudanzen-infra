variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "services" {
  description = "Service names to enable, e.g. container.googleapis.com."
  type        = list(string)
}
