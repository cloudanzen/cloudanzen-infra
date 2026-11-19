# ADR-0003: Secret authority, delivery and rotation

- Date: 2026-11-18
- Status: Accepted direction; bootstrap/rotation validation pending
- Plan: [IaC/GitOps implementation plan](../iac-gitops-implementation-plan.md)

## Context

Environment secrets need a recoverable authority outside the cluster. Git-reviewed infrastructure must be reproducible without copying production passwords or putting secret payloads into Terraform state. Database/operator credentials need one clear owner.

## Decision

Use Google Secret Manager per environment project. External Secrets Operator (ESO) reads it through GKE Workload Identity and creates namespaced runtime Kubernetes Secrets. Use scoped identities and named secret access, with no staging access to production. See [ESO's Google provider](https://external-secrets.io/latest/provider/google-secrets-manager/).

| Secret class | Authority and delivery |
| --- | --- |
| Application signing/encryption keys, OAuth secrets and application service credentials | Secret Manager → ESO → only the required workload |
| Application and migration database passwords | Separate values/roles in Secret Manager; ESO supplies the supported CNPG role configuration and appropriate consumers |
| Operator-internal database credentials/certificates | Explicitly inventoried operator lifecycle; never independently regenerate application passwords |
| Argo repository credential | Secret Manager; restricted initial bootstrap, followed by ESO ownership |
| GCP execution identities | Short-lived federation/dynamic credentials; no service-account JSON keys |
| Non-federated provider/API/agent enrollment credentials | Restricted automation credential store for the selected execution mode; renewal and revocation documented |
| Customer connector credentials | Existing tenant-scoped application storage; deployment configuration holds only required encryption-key material |

Terraform manages containers, IAM and references only. Do not move payloads through ordinary secret-version resources/data sources, Helm values, Kubernetes Secret resources, outputs or VM startup metadata. `sensitive` redacts output but does not guarantee omission from state or saved plans. Protect those artifacts regardless. See [Terraform sensitive-data guidance](https://developer.hashicorp.com/terraform/language/manage-sensitive-data).

Supply initial values through secure input to an authorized bootstrap workflow. Do not write them to Git, shell arguments/history, CI comments or chat. The frontend receives public configuration only. Future Firebase web configuration is not an Admin credential; private keys and provider secrets remain protected.

Resolve the private-Git bootstrap dependency explicitly: install Argo, securely seed its read-only repository credential from Secret Manager, then let it install ESO from Git. Hand the credential Secret to ESO once ready; the seed script must refuse to overwrite an ESO-owned Secret. The credential must not pass through Terraform or Helm. Terraform continues to own Argo installation/upgrades.

Rotation updates the actual credential, reconciles the selected secret version, reloads/restarts consumers, verifies access and retires the old version after the recovery window. ESO synchronization does not change a PostgreSQL password or reload an environment variable automatically. Validate the pinned CNPG managed-role behavior, rather than assuming bootstrap-secret updates rotate existing roles. Signing/encryption keys require separate compatibility and recovery procedures.

## Alternatives and consequences

- HCP workspace variables for every application secret: rejected as the runtime authority; keep only necessary automation credentials there when HCP is selected.
- Kubernetes-only secrets: insufficient for independent recovery and consistent environment authority.
- An additional Vault deployment: deferred; no current requirement justifies operating it.

Kubernetes Secrets remain readable runtime copies to appropriately privileged actors. Restrict both secret-reading and workload-creation privileges. Runtime pods must not receive migration credentials. Prevent accidental secret-container destruction and distinguish reversible disablement from permanent version destruction.

## Validation and cost

Test environment isolation, missing-version behavior, redacted logs/state handling, Argo bootstrap handoff and disposable staging database-credential rotation. Record owners and recovery instructions. Verify that historical encryption keys remain available for necessary data recovery.

Include secret versions, accesses and retained old versions in cost estimates; ESO also uses cluster compute. Google bills enabled and disabled versions as active and shares free allowances across a billing account. See [Secret Manager pricing](https://cloud.google.com/secret-manager/pricing). Exact account cost remains unverified.
