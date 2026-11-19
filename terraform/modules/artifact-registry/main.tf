# Docker repository for CloudAnzen images. Tags are immutable so a release
# is always identified by digest. Cleanup starts in dry-run mode.

resource "google_artifact_registry_repository" "this" {
  project       = var.project_id
  location      = var.region
  repository_id = var.repository_id
  format        = "DOCKER"
  description   = "CloudAnzen application images"
  labels        = var.labels

  docker_config {
    immutable_tags = true
  }

  cleanup_policy_dry_run = true

  cleanup_policies {
    id     = "keep-recent-releases"
    action = "KEEP"
    most_recent_versions {
      keep_count = var.keep_recent_versions
    }
  }

  cleanup_policies {
    id     = "delete-old-untagged"
    action = "DELETE"
    condition {
      tag_state  = "UNTAGGED"
      older_than = "2592000s"
    }
  }
}
