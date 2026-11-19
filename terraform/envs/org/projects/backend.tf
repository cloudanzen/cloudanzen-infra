terraform {
  cloud {
    organization = "cloudanzen"

    workspaces {
      name = "gcp-org-projects"
    }
  }
}
