# CloudAnzen architecture decisions

Recorded: 2026-11-18. These records describe the agreed direction for the new GCP platform. They do not claim that infrastructure or application features have been implemented, provisioned or migrated.

The [IaC/GitOps implementation plan](../iac-gitops-implementation-plan.md) is the canonical execution plan. An accepted direction can have unresolved implementation prerequisites; those are listed explicitly below and in each ADR. Amendments must update the affected ADR and plan together. Record a superseding ADR when changing an accepted architectural decision.

| ADR | Decision | Status | Remaining gate |
| --- | --- | --- | --- |
| [0001](0001-gcp-platform-and-delivery-ownership.md) | GKE shared platform; Terraform/Argo/GitHub Actions ownership | Accepted direction | Compatibility spike, migration replay and restore evidence |
| [0002](0002-terraform-state-and-execution.md) | Separate environment/lifecycle state; conditional HCP Free selection | Accepted selection policy; backend choice pending verification | Account, existing state, permissions, private execution and cost checks |
| [0003](0003-secret-authority-and-delivery.md) | Secret Manager + ESO; secret payloads excluded from Terraform | Accepted direction | Database rotation and private-Git bootstrap validation |
| [0004](0004-tenant-hostnames-and-onboarding.md) | Organization-specific hostnames, one shared backend, platform-led onboarding | Accepted target architecture; customer rollout deferred | Exact domain suffix, registry/session implementation and isolation tests |
| [0005](0005-firebase-identity-platform-migration.md) | Future Firebase Authentication with Identity Platform; CloudAnzen retains authorization | Accepted migration direction; detailed cutover design pending | Tenant/SSO/callback spike, user/MFA migration design, pricing and cutover approval |
| [0006](0006-interim-single-cluster-topology.md) | One shared GKE cluster: staging and production namespaces; per-environment projects for secrets/data | Accepted (interim); supersedes ADR-0001 cluster topology | Second-cluster triggers; upgrade testing on a temporary cluster |

The current Railway deployment remains outside this project. Documentation in this directory does not authorize its retirement or an authentication cutover.
