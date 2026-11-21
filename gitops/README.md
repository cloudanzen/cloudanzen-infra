# GitOps (Argo CD)

Argo CD reconciles this directory continuously (automated sync with prune and self-heal). Terraform (`terraform/envs/platform/bootstrap`) only installs Argo CD and the root Application that points at `bootstrap/`.

| Path | Synced by | Contents |
| --- | --- | --- |
| `bootstrap/` | root Application (project `default`) | AppProjects and the Applications below, ordered by sync wave |
| `platform/baseline/` | `platform-baseline` (project `platform`) | Environment namespaces, quotas, limit ranges, priority classes, default-deny network policies |
| operators | Applications in `bootstrap/` (project `platform`) | cert-manager, External Secrets Operator, CloudNativePG operator, Barman Cloud plugin |
| `platform/gateway/` | `gateway` (project `platform`) | The shared GKE Gateway in namespace `gateway`: HTTP-to-HTTPS redirect, one HTTPS listener per environment (each admits routes from its own namespace only), TLS 1.2+ policy. Its address, certificate map and SSL policy are Terraform-owned (`terraform/envs/platform/foundation`) |
| `apps/staging/data/` | `staging-data` (project `cloudanzen-staging`) | Secret Manager wiring (SecretStore, ExternalSecrets), PostgreSQL 18 + pgvector (CloudNativePG, 3 instances, backups to GCS), Valkey, and the connection-string Secrets the app chart uses |
| `apps/staging/app/values.yaml` | `staging-app` (project `cloudanzen-staging`) | Staging values for [`charts/cloudanzen`](../charts/cloudanzen): image digests, hosts, secret mapping, Gateway listener for its HTTPRoutes |

Projects (ADR-0006): `platform` may install cluster-wide operators. `cloudanzen-staging` and `cloudanzen-prod` may deploy only into their own namespace, may not create cluster-scoped resources, and may not change quotas, limit ranges or network policies set by the baseline.

Emergency changes made with `kubectl` are reverted by self-heal. To make one deliberately, disable automated sync on that Application, make the change, then put it in Git and re-enable sync (break-glass procedure in the plan, section 7).
