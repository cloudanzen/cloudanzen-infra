# Keyless GitHub Actions -> GCP authentication (ADR-0002/0003). Tokens are
# accepted only from the configured organization and repositories; each CI
# identity is a service account that only listed repositories can
# impersonate. No service-account keys are created.

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = var.pool_id
  display_name              = "GitHub Actions"
  description               = "OIDC federation for ${var.github_owner} GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
    "attribute.ref"              = "assertion.ref"
    "attribute.environment"      = "assertion.environment"
  }

  attribute_condition = format(
    "assertion.repository_owner == '%s' && assertion.repository in [%s]",
    var.github_owner,
    join(", ", [for r in local.all_repositories : "'${r}'"]),
  )

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

locals {
  all_repositories = distinct(flatten([for id in values(var.identities) : id.repositories]))

  bindings = flatten([
    for name, id in var.identities : [
      for repo in id.repositories : {
        key  = "${name}/${repo}"
        name = name
        repo = repo
      }
    ]
  ])
}

resource "google_service_account" "ci" {
  for_each = var.identities

  project      = var.project_id
  account_id   = each.key
  display_name = each.value.description
}

resource "google_service_account_iam_member" "wif" {
  for_each = { for b in local.bindings : b.key => b }

  service_account_id = google_service_account.ci[each.value.name].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${each.value.repo}"
}
