# ADR-0002: Terraform state, execution and cost policy

- Date: 2026-11-18
- Status: Accepted selection policy; backend/execution choice pending account verification
- Plan: [IaC/GitOps implementation plan](../iac-gitops-implementation-plan.md)

## Context

Existing roots select HCP Terraform workspaces named `staging` and `production`. A backend declaration does not establish the account's subscription, resource usage or whether state is empty. Failed historical runs do not prove that no resources were created.

## Decision

Keep staging and production credentials/state separate. Also separate cloud foundation from Kubernetes bootstrap so the cluster exists before initializing providers that access its API. Workspaces are logical configuration/state boundaries, not dedicated servers and not sufficient IAM boundaries by themselves.

Retain HCP only if its verified Free subscription, resource allowance, permissions and execution features meet this design. Do not buy a paid plan merely to create workspaces. If unsuitable, select Terraform CLI in GitHub Actions with a versioned, access-controlled GCS backend and locking before creating new state. Both options must satisfy the same review, isolation and recovery requirements.

Proposed HCP names are `gcp-staging-foundation`, `gcp-staging-bootstrap`, `gcp-prod-foundation` and `gcp-prod-bootstrap`. Preserve existing workspace names and ownership until inventoried. For GCS, use equivalent separate state roots and environment permissions.

State storage and execution location are separate decisions. Prove bootstrap-runner access to the cluster API. Where private networking requires it, use an appropriately isolated runner/agent outside the managed cluster; include its VM, network and credential lifecycle in the estimate. A suitable HCP plan does not make the agent host free. Bootstrap the trust/state backend before dependent runs, using a documented authorized administrator process.

Use one writer/trigger path per state. In the HCP option, GitHub Actions requests a run for the reviewed commit and duplicate VCS auto-apply is disabled. In the GCS option, Actions executes Terraform with the reviewed commit/plan and short-lived GCP credentials. Production applies require approval. Re-plan when state or the candidate changes. Do not expose production credentials to unreviewed external PR code.

There is no automatic backend fallback, paid upgrade or state deletion. Any migration requires paused writers, a protected backup, lineage/serial verification, a no-change plan and an explicit switch to one writer. Store state outside GKE and outside Git; restrict saved plans and state access.

## Costs and alternatives

HCP currently lists 500 managed resources per Free organization and unlimited workspaces. Four workspaces do not mean four free allowances. Verify the account and then-current terms before provisioning. See [HCP limits](https://developer.hashicorp.com/terraform/cloud-docs/overview) and [pricing](https://www.hashicorp.com/en/pricing).

GCS avoids an HCP subscription, but still incurs storage/operation and execution costs. Its Terraform backend supports state locking; enable object versioning and environment-specific access. See [GCS backend](https://developer.hashicorp.com/terraform/language/backend/gcs).

CLI workspace selection alone was rejected as the sole staging/production isolation mechanism. Local-only state was rejected because team locking, recovery and access control need a remote design.

## Completion evidence

Record the selected backend, actual subscription/usage, state ownership, execution identities, production approval mechanism and cost estimate before foundation apply. Demonstrate locking, concurrent-run exclusion, private API access, restricted plan summaries, drift reporting and state recovery. Near-limit alerts lead to a decision, not an automatic migration.
