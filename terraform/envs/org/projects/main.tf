# Environment projects (ADR-0006). The shared cluster lives in
# cloudanzen-gke; each environment's secrets, backups and service accounts
# live in its own project so staging identities cannot reach production
# data. The apply identity becomes owner of the projects it creates.

resource "google_project" "env" {
  for_each = var.environment_projects

  project_id          = each.value.project_id
  name                = each.value.name
  org_id              = var.org_id
  billing_account     = var.billing_account
  auto_create_network = false
  deletion_policy     = "PREVENT"

  labels = { environment = each.key }
}

resource "google_project_iam_member" "plan_viewer" {
  for_each = {
    for pair in setproduct(keys(var.environment_projects), ["roles/viewer", "roles/iam.securityReviewer"]) :
    "${pair[0]}/${pair[1]}" => { env = pair[0], role = pair[1] }
  }

  project = google_project.env[each.value.env].project_id
  role    = each.value.role
  member  = "serviceAccount:${var.plan_service_account_email}"
}
