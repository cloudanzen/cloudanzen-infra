# HCP Terraform workspace for the Kubernetes bootstrap (ADR-0002: separate
# from the cloud foundation so the cluster exists before these providers
# initialise).
terraform {
  cloud {
    organization = "cloudanzen"

    workspaces {
      name = "gcp-platform-bootstrap"
    }
  }
}
