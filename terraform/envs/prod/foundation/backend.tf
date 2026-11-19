# HCP Terraform per ADR-0002 (default); verify/create the workspace before
# the first plan. CI validates with `terraform init -backend=false`.
terraform {
  cloud {
    organization = "cloudanzen"

    workspaces {
      name = "gcp-prod-foundation"
    }
  }
}
