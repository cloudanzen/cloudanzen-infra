# GCP platform Terraform

New GCP roots for the platform described in [the implementation plan](../docs/iac-gitops-implementation-plan.md). The legacy `environments/` and `modules/` roots are unchanged and are not used here.

## Layout

| Path | Purpose | ADR |
| --- | --- | --- |
| `envs/platform/foundation` | Shared cluster project: APIs, VPC, Cloud NAT with reserved static egress IPs, one GKE Autopilot cluster, Artifact Registry, keyless GitHub Actions federation for image publishing | 0001, 0006 |
| `envs/staging/foundation` | Staging project: Secret Manager containers, database backup bucket, service accounts for the `cloudanzen-staging` namespace | 0003, 0006 |
| `envs/prod/foundation` | Production project: the same for the `cloudanzen-prod` namespace | 0003, 0006 |
| `modules/*` | `project-services`, `network`, `gke-autopilot`, `artifact-registry`, `github-wif`, `env-project` | — |

## Rules

- **No secret values in Terraform.** Roots create Secret Manager *containers* and IAM only. Values are added through the seeding runbook, so they never enter state or plans. CI rejects secret-version resources, `random_password` and service-account keys.
- **No committed `terraform.tfvars`** under `terraform/`. Copy each `terraform.tfvars.example`; real non-secret values go to the selected executor.
- **Provider lock files are committed.** Update them with `terraform providers lock -platform=linux_amd64 -platform=darwin_arm64`.
- Identity inputs (`project_id`, `region`, `cluster_project_id`) have no defaults, so a missing value fails instead of targeting another environment.
- Address reservations, secret containers and backup buckets use `prevent_destroy`; the cluster has `deletion_protection`.

## Apply order (not yet run)

1. Account owner confirms the organization/folder, billing account, region and the three project IDs, and grants the bootstrap identity (ADR-0002).
2. Select and create the state workspaces (`gcp-platform-foundation`, `gcp-staging-foundation`, `gcp-prod-foundation`) or the GCS alternative (ADR-0002).
3. `envs/platform/foundation`, then `envs/staging/foundation`, then `envs/prod/foundation` (pass `cluster_project_id`).
4. Seed staging secret versions through the protected runbook (names in the environment root's `secret_ids`; mapping in `docs/configuration-inventory.csv`).
5. Argo CD bootstrap root (PR6, not yet added).

## Not yet included

- Remote plans and applies in CI (needs the backend and executor decision).
- Argo CD bootstrap, platform add-ons and the application chart (PR6–PR7).
- GitHub environment protection for the new roots, a Terraform plan identity and budget alerts.
- Control-plane allowlist (`master_authorized_cidrs`) for the bootstrap executor.

## Local validation

```sh
terraform fmt -recursive -check terraform
for r in terraform/envs/*/foundation; do
  (cd "$r" && terraform init -backend=false -lockfile=readonly && terraform validate)
done
```
