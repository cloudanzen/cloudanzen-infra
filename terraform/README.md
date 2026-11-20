# GCP platform Terraform

New GCP roots for the platform described in [the implementation plan](../docs/iac-gitops-implementation-plan.md). The legacy `environments/` and `modules/` roots are unchanged and are not used here.

## Layout

| Path | Purpose | ADR |
| --- | --- | --- |
| `envs/org/projects` | Creates the staging and production projects under the organization and links billing; grants the plan identity read access | 0006 |
| `envs/platform/foundation` | Shared cluster project: APIs, VPC, Cloud NAT with reserved static egress IPs, one GKE Autopilot cluster, Artifact Registry, keyless GitHub Actions federation for image publishing | 0001, 0006 |
| `envs/platform/bootstrap` | Installs Argo CD (Helm) and the root Application that reconciles `gitops/`; grants the plan identity read access to Helm release records | 0001 |
| `envs/staging/foundation` | Staging project: Secret Manager containers, database backup bucket, service accounts for the `cloudanzen-staging` namespace | 0003, 0006 |
| `envs/prod/foundation` | Production project: the same for the `cloudanzen-prod` namespace | 0003, 0006 |
| `modules/*` | `project-services`, `network`, `gke-autopilot`, `artifact-registry`, `github-wif`, `env-project` | — |

## Rules

- **No secret values in Terraform.** Roots create Secret Manager *containers* and IAM only. Values are added through the seeding runbook, so they never enter state or plans. CI rejects secret-version resources, `random_password` and service-account keys.
- **No committed `terraform.tfvars`** under `terraform/`. Copy each `terraform.tfvars.example`; real non-secret values go to the selected executor.
- **Provider lock files are committed.** Update them with `terraform providers lock -platform=linux_amd64 -platform=darwin_arm64`.
- Identity inputs (`project_id`, `region`, `cluster_project_id`) have no defaults, so a missing value fails instead of targeting another environment.
- Address reservations, secret containers and backup buckets use `prevent_destroy`; the cluster has `deletion_protection`.

## First run

Inputs: GCP organization and billing account (HCP workspace variables only, never committed), region `asia-northeast1`, shared project `cloudanzen-gke`, HCP organization `cloudanzen`.

1. **Trust bootstrap (GCP organization admin, once).** With `gcloud` signed in as an organization administrator:

   ```sh
   ORG_ID=<org-id> BILLING_ACCOUNT=<billing-account> scripts/bootstrap/hcp-gcp-trust.sh
   ```

   It creates the HCP Terraform workload identity pool and provider in `cloudanzen-gke`, plus two service accounts. `terraform-plan` is read-only. `terraform-apply` has Owner on `cloudanzen-gke`, Project Creator on the organization and Billing Account User. Each workspace's plan and apply phases map to their own account. No keys are created.
2. **HCP workspaces** in organization `cloudanzen`: create `gcp-org-projects`, `gcp-platform-foundation`, `gcp-platform-bootstrap`, `gcp-staging-foundation` and `gcp-prod-foundation`, each with its working directory set to its path in this repository (so `terraform/modules` is uploaded),, in CLI/API-driven mode with remote execution and no VCS auto-apply (ADR-0002). On each, set the four `TFC_GCP_*` environment variables the script prints.
3. **Workspace variables (Terraform category, non-secret):**

   | Workspace | Variables |
   | --- | --- |
   | `gcp-org-projects` | `org_id`, `billing_account` |
   | `gcp-platform-foundation` | `project_id = cloudanzen-gke`, `region = asia-northeast1` |
   | `gcp-platform-bootstrap` | `project_id = cloudanzen-gke`, `region = asia-northeast1` |
   | `gcp-staging-foundation` | `project_id = cloudanzen-staging`, `cluster_project_id = cloudanzen-gke`, `region = asia-northeast1` |
   | `gcp-prod-foundation` | `project_id = cloudanzen-prod`, `cluster_project_id = cloudanzen-gke`, `region = asia-northeast1` |

4. Apply in order, reviewing each plan: `gcp-org-projects`, then `gcp-platform-foundation`, then `gcp-staging-foundation`, then `gcp-prod-foundation`. If `cloudanzen-staging` or `cloudanzen-prod` is already taken globally, override `environment_projects`.
5. Publish the `nat_ip_addresses` output for customer allowlisting.
6. Seed staging secret versions through the protected runbook (names in the environment root's `secret_ids`; mapping in `docs/configuration-inventory.csv`).
7. `gcp-platform-bootstrap`: installs Argo CD, which then syncs `gitops/` (projects, namespace baseline, cert-manager, External Secrets, CloudNativePG and the Barman Cloud plugin).

## Not yet included

- Remote plans and applies in CI (needs the backend and executor decision).
- Data services and the application chart (PR7).
- GitHub environment protection for the new roots and budget alerts.
- Remote CI runs still need an HCP team token in the `TF_API_TOKEN` GitHub secret (currently empty).
- Control-plane allowlist (`master_authorized_cidrs`) for the bootstrap executor.

## Local validation

```sh
terraform fmt -recursive -check terraform
for r in terraform/envs/*/foundation terraform/envs/org/projects terraform/envs/platform/bootstrap; do
  (cd "$r" && terraform init -backend=false -lockfile=readonly && terraform validate)
done
```
