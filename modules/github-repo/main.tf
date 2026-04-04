terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

resource "github_repository" "this" {
  name                   = var.repository
  allow_auto_merge       = var.enable_auto_merge
  delete_branch_on_merge = var.delete_branch_on_merge

  # Prevent Terraform from managing fields we don't care about
  lifecycle {
    ignore_changes = [
      description,
      homepage_url,
      topics,
      visibility,
      has_issues,
      has_projects,
      has_wiki,
      has_downloads,
    ]
  }
}

resource "github_branch_protection" "main" {
  repository_id = github_repository.this.node_id
  pattern       = var.default_branch

  required_status_checks {
    strict   = true
    contexts = var.required_status_checks
  }

  enforce_admins = false

  # No required PR reviews for solo developer
  # Add required_pull_request_reviews block when team grows
}
