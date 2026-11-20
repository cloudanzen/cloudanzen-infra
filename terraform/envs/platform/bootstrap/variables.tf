variable "project_id" {
  description = "Shared cluster project. No default: must be explicit."
  type        = string
}

variable "region" {
  description = "Cluster region. No default: must be explicit."
  type        = string
}

variable "cluster_name" {
  description = "Shared GKE cluster name."
  type        = string
  default     = "cloudanzen"
}

variable "gitops_repo_url" {
  description = "Git repository Argo CD reconciles from (public, so no repository credential is needed)."
  type        = string
  default     = "https://github.com/cloudanzen/cloudanzen-infra.git"
}

variable "gitops_revision" {
  description = "Branch, tag or commit Argo CD tracks."
  type        = string
  default     = "main"
}

variable "argocd_chart_version" {
  description = "argo-helm argo-cd chart version (10.18.2 = Argo CD v3.6.2, a supported line)."
  type        = string
  default     = "10.18.2"
}

variable "argocd_apps_chart_version" {
  description = "argo-helm argocd-apps chart version (creates the root Application)."
  type        = string
  default     = "2.0.8"
}

variable "plan_identity" {
  description = "HCP Terraform plan service account; granted read access to Helm release records."
  type        = string
  default     = "terraform-plan@cloudanzen-gke.iam.gserviceaccount.com"
}
