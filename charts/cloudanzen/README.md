# charts/cloudanzen

CloudAnzen API, worker and frontend for the GKE platform. One release per environment namespace, deployed by Argo CD (`gitops/bootstrap/staging-app.yaml`) with that environment's values (`gitops/apps/<env>/app/values.yaml`).

## What it deploys

| Resource | Notes |
| --- | --- |
| `cloudanzen-migrate` Job | Argo `PreSync` hook: `prisma migrate deploy` from the `backend-migrate` image, before any workload changes. A failed migration stops the sync; workloads keep running the previous release |
| `cloudanzen-api` | `node dist/server.js` on port 3000; startup and readiness probes on `/health`, TCP liveness (a database failover does not restart pods) |
| `cloudanzen-worker` | Same image and configuration, `node dist/worker.js`; health server on 8080 |
| `cloudanzen-frontend` | nginx SPA on 8080 with read-only root filesystem; `/config.js` generated from `CLOUDANZEN_*` at start |
| `cloudanzen-backend-env` ConfigMap | `NODE_ENV=production`, `APP_ENV`, and every public URL and OAuth callback derived from `urls.*`, so no production default from the backend schema applies |
| `cloudanzen-backend-secrets` ExternalSecret | `backend.secretEnv`: environment variable to Secret Manager secret ID |
| HTTPRoutes and HealthCheckPolicies | Only with `gateway.enabled`; attach to the shared Gateway owned by the platform layer |

## Contracts

- **Images by digest only.** `values.schema.json` rejects anything but `sha256:` digests. A release changes the digests in the environment's values file; production promotes the same digests.
- **Argo hooks only.** Argo ignores every Helm hook once an Application has an Argo hook, so the chart uses `argocd.argoproj.io/hook` exclusively. CI fails on any Helm hook annotation.
- **Connection strings come from the data application** (`cloudanzen-runtime-connections`, `cloudanzen-migrate-connection`), so they exist before the PreSync hook. Runtime pods never receive the migration credential.
- **No secret values** in values files, Git or Argo: only secret IDs (ADR-0003). Add a `secretEnv` entry only after the secret has a version, because one missing secret blocks the whole ExternalSecret.
- **Secret rotation** updates the Kubernetes Secret within `refreshInterval` (1h), but running pods keep the old value until they restart. Restart the Deployments after a rotation.
- The backend's deployment guard (`APP_ENV`) and the frontend entrypoint both refuse non-staging hosts in staging, and staging hosts in production.

## Local checks

```sh
helm lint charts/cloudanzen -f gitops/apps/staging/app/values.yaml
helm template cloudanzen charts/cloudanzen -n cloudanzen-staging -f gitops/apps/staging/app/values.yaml
```

## Known gaps (M1)

- Evidence uploads use local disk (`UPLOAD_DIR`) unless `EVIDENCE_*` object storage is configured, so files do not survive pod restarts and are not shared between pods.
- No autoscaling yet; size replicas and requests from measured staging use.
- Root filesystem is writable for the API and worker (Chromium PDF rendering and uploads); hardening is a follow-up.
- Database connections are not TLS-verified inside the cluster (traffic stays in the namespace, restricted by NetworkPolicy).
