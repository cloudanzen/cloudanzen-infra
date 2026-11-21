# staging environment project (ADR-0003, ADR-0006). Workloads run in the
# cloudanzen-staging namespace of the shared cluster.

locals {
  environment = "staging"
  namespace   = "cloudanzen-staging"

  # Secret containers only. Values are seeded through the runbook and never
  # pass through Terraform. Names map to keys in docs/configuration-inventory.csv.
  secret_ids = [
    "jwt-secret",
    "encryption-key",
    "oauth-state-signing-key",
    "google-client-secret",
    "github-client-secret",
    "resend-api-key",
    "openai-api-key",
    "anthropic-api-key",
    "turnstile-secret",
    "public-academy-attempt-hmac-secret",
    "public-academy-completion-hmac-secret",
    "public-academy-manage-hmac-secret",
    "trust-grant-hash-secret",
    "trust-viewer-hash-secret",
    "trust-share-link-hmac-secret",
    "trust-subscriber-hmac-secret",
    "trust-viewer-erasure-hmac-secret",
    "db-app-password",
    "db-migrate-password",
    "redis-password",
  ]
}

module "services" {
  source     = "../../../modules/project-services"
  project_id = var.project_id
  services = [
    "iam.googleapis.com",
    "secretmanager.googleapis.com",
    "storage.googleapis.com",
  ]
}

module "env" {
  source                = "../../../modules/env-project"
  project_id            = var.project_id
  environment           = local.environment
  namespace             = local.namespace
  cluster_workload_pool = "${var.cluster_project_id}.svc.id.goog"
  secret_ids            = local.secret_ids
  backup_location       = var.region
  labels                = { component = "env-foundation" }

  depends_on = [module.services]
}

# Public hostnames for this environment on the shared Gateway (ADR-0004).
# The certificate map entry and certificate live in the cluster project; the
# A records point at the Gateway address the platform foundation reserves.
module "edge" {
  source             = "../../../modules/env-edge"
  cluster_project_id = var.cluster_project_id
  environment        = local.environment
  zone_name          = "cloudanzen.com"
  base_domain        = "staging.cloudanzen.com"
  hostnames          = ["app", "api", "platform"]
  labels             = { component = "env-edge", environment = local.environment }
}
