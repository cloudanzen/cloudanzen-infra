# ADR-0001: GCP shared platform and delivery ownership

- Date: 2026-11-18
- Status: Accepted direction; implementation pending. Cluster topology superseded by [ADR-0006](0006-interim-single-cluster-topology.md) (one shared cluster)
- Scope: New GCP environments; existing Railway/Vercel deployment unchanged
- Plan: [IaC/GitOps implementation plan](../iac-gitops-implementation-plan.md)

## Context

CloudAnzen needs reproducible staging and production environments with reviewed configuration, repeatable releases and a path to automated customer onboarding. A customer subdomain must not require a separate application deployment by default.

## Decision

Cluster topology is decided by [ADR-0006](0006-interim-single-cluster-topology.md): one shared GKE Autopilot cluster with staging and production namespaces, and per-environment GCP projects for secrets and data. Deploy shared backend, worker and frontend services within each environment. Customer organizations share these services with application and database tenant isolation; dedicated customer deployments are a separate future offering.

Assign one ongoing manager to each resource:

| Owner | Resources and responsibilities |
| --- | --- |
| Terraform | Projects, network, GKE, registry, backup storage, identities/IAM, shared DNS/certificate infrastructure, secret containers, GitHub environment settings and the Argo installation/root Application |
| Terraform bootstrap | Install and upgrade Argo in each cluster's `argocd` namespace; it is not also managed by Argo |
| Argo CD | Platform add-ons, data-service manifests, workload Helm releases and routing; reconcile approved Git revisions |
| GitHub Actions | Build/test images, publish digests, request reviewed infrastructure runs, open promotion PRs, invoke QA and record deployment results |
| CloudAnzen onboarding service | Tenant registry, organization configuration, invitations and future authentication tenants; see [ADR-0004](0004-tenant-hostnames-and-onboarding.md) |

Use CloudNativePG for in-cluster PostgreSQL and maintained Redis/Valkey images with persistent storage. Treat the proposed PostgreSQL/pgvector image and three-instance database topology as validation/cost gates, not proven compatibility. Runtime and migration identities are separate; historical privileged migrations require a real-role replay before choosing migration permissions.

The app chart uses Argo CD hook annotations only. Argo maps Helm `pre-upgrade` hooks to `PreSync`, but ignores all Helm hooks once an application contains any Argo hook ([Argo Helm docs](https://argo-cd.readthedocs.io/en/stable/user-guide/helm/)); mixing them would make migration ordering ambiguous. CI rejects `helm.sh/hook` annotations in the app chart.

Pin an Argo CD minor version in upstream support (3.3 reached end of life on 2026-11-03; 3.4, 3.5 and 3.6 were supported at review time). Terraform owns upgrades: staging first, reviewed quarterly, never more than one supported minor behind.

Separate platform, data/credential and app Argo Applications. Before an app migration hook runs, verify controllers, CRDs, ServiceAccounts, credentials, database roles/connectivity and Redis. Argo sync waves alone do not prove child readiness. A `PreSync` migration cannot depend on an ordinary resource that the same application has not created yet. See [Argo sync phases](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-waves/).

Build once and promote immutable image digests. Backend and worker use the same digest. Frontend configuration is supplied at runtime. Production promotion references the exact passing staging release tuple and reviewed environment differences. GitHub Releases record successful deployment; publishing a release must not bypass promotion gates. GitHub Actions does not independently deploy or migrate Argo-owned workloads.

## Alternatives considered

- Direct deployment from GitHub Actions: retains a second source of deployment behavior and lacks the selected continuous reconciliation model.
- One cluster per standard customer: introduces provisioning and operational cost before a dedicated-isolation requirement exists.
- Argo self-management and Terraform managing the same installation: creates competing owners.

## Consequences and validation

- Shared infrastructure requires tenant isolation, resource limits and monitoring; hostnames alone provide no data isolation.
- Database operations remain CloudAnzen's responsibility. Restore rehearsals and measured RPO/RTO are required before customers use the new platform.
- Cluster/state/credential recovery must work without the managed cluster being healthy.
- Verify first install, failed migration, repeated sync, exact-digest promotion, drift reporting and compatible rollback. Database rollback is a distinct recovery process, not a Helm rollback.
- Separate legacy release paths from GCP jobs. Do not trigger legacy applies because a new documentation or GitOps manifest changed.
