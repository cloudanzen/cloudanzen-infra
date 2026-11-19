# State backend: HCP Terraform per ADR-0002 (default). The workspace must be
# verified/created and its execution mode set before the first plan; until
# then CI validates this root with `terraform init -backend=false`.
terraform {
  cloud {
    organization = "cloudanzen"

    workspaces {
      name = "gcp-platform-foundation"
    }
  }
}
