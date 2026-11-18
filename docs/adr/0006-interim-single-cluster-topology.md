# ADR-0006: Interim single GKE cluster for staging and production

- Date: 2026-11-18
- Status: Accepted (interim); supersedes the cluster-topology part of [ADR-0001](0001-gcp-platform-and-delivery-ownership.md)
- Plan: [IaC/GitOps implementation plan](../iac-gitops-implementation-plan.md)

## Context

ADR-0001 chose separate GCP projects and GKE Autopilot clusters for staging and production. The product owner decided to start with **one cluster** to reduce cost and setup effort, hosting both staging and production by namespace, and to add the second cluster later. A second cluster's management fee is about $73/month; the GKE free-tier credit ($74.40/month per billing account) covers one cluster ([GKE pricing](https://cloud.google.com/kubernetes-engine/pricing)).

## Decision

Run one GKE Autopilot cluster in a dedicated platform project. Staging and production are separate namespaces in it. Keep secrets, backups and data permissions in per-environment projects so the strongest boundaries that do not require a second cluster are still in place.

| Boundary | Design |
| --- | --- |
| GCP projects | `cloudanzen-gke` (candidate ID): cluster, Artifact Registry, VPC, Cloud NAT. `cloudanzen-staging` and `cloudanzen-prod`: Secret Manager, backup buckets, environment service accounts |
| Namespaces | `cloudanzen-staging` and `cloudanzen-prod` for workloads and data; shared system namespaces for Argo CD, ESO, CloudNativePG, cert-manager |
| Workload identity | Each namespace's Kubernetes service accounts bind only to that environment's GCP service accounts; staging identities have no IAM on production projects |
| Secrets | Namespaced ESO `SecretStore` per environment pointing to that environment's project; no `ClusterSecretStore` for application secrets |
| Argo CD | One instance. Separate `AppProject` per environment restricting source paths (`gitops/apps/staging` or `gitops/apps/prod`) and destination namespace; production sync requires the reviewed production promotion |
| Data | Separate CloudNativePG cluster, Redis and backup bucket per namespace; no cross-namespace database access |
| Network | Default-deny NetworkPolicies per namespace; no traffic between staging and production namespaces |
| Capacity | ResourceQuota and LimitRange per namespace; a higher PriorityClass for production so staging is evicted first under pressure |
| Routing | Separate HTTPRoutes and certificates per environment hostname; staging uses `*.staging.app.cloudanzen.com` |
| Human access | No standing cluster-admin; namespace-scoped roles; break-glass access is time-limited and audited |

## Consequences

- **Shared blast radius.** The control plane, GKE version and node upgrades, the single Argo instance, cluster-wide operators and their CRDs (CloudNativePG, ESO, cert-manager), and the Gateway affect both environments at once. Staging can no longer pre-test these platform upgrades.
- **Mitigation for upgrades.** Use a GKE release channel with maintenance windows and exclusions. Pin operator and Argo versions, and test each platform upgrade on a temporary throwaway cluster (the spike pattern) before applying it to the shared cluster. Application releases are still tested in staging first.
- **Shared egress IPs.** Both namespaces leave through the same Cloud NAT addresses. A customer that allowlists CloudAnzen's IPs also admits staging traffic, so staging must only use provider test accounts, never customer systems.
- **Compliance.** Environment separation (for example ISO/IEC 27001:2022 control A.8.31) is implemented through namespaces, separate projects for secrets and data, and access controls. Document this; an auditor or customer may require physical cluster separation.
- **Cost.** One cluster fee, offset by the free-tier credit.

## Triggers for the second cluster

Create a dedicated production cluster with the same Terraform module when any of these occurs, and in any case before general availability:

- a customer contract or audit requires separate production infrastructure;
- a platform upgrade or operator incident affects production;
- production resource use or scheduling pressure affects reliability;
- the number of production tenants exceeds an agreed threshold.

Migration path: provision the new cluster from the same modules, restore the production CloudNativePG cluster from its backup into the new cluster, switch DNS, then remove the production namespace from the shared cluster. Staging remains on the original cluster.
