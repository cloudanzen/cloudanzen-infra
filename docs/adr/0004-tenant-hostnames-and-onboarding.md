# ADR-0004: Tenant hostnames and platform-led onboarding

- Date: 2026-11-18
- Status: Accepted target architecture; customer rollout is a later milestone
- Plan: [IaC/GitOps implementation plan](../iac-gitops-implementation-plan.md)
- Related: [Identity migration](0005-firebase-identity-platform-migration.md), [delivery ownership](0001-gcp-platform-and-delivery-ownership.md)

## Context

The product owner wants `platform.cloudanzen.com` to automate onboarding, assign an organization-specific subdomain and restrict that organization's users to its workspace. Every customer subdomain must reach the same shared backend. Neither a hostname nor an email domain is proof of membership.

## Decision

Keep the platform administration surface at `platform.cloudanzen.com`. Use a configurable customer-host suffix; `acme.app.cloudanzen.com` and `contoso.app.cloudanzen.com` are examples, not provisioned or approved DNS records. Define a separate staging suffix. Confirm the exact suffix before DNS/certificate provisioning.

**Confirmed by the product owner (2026-11-18):**

| Purpose | Hostname | When |
| --- | --- | --- |
| Customer workspaces | `<tenant>.app.cloudanzen.com` | From production go-live |
| Staging workspaces | `<tenant>.staging.app.cloudanzen.com` | M1 |
| Canary ring | `app.cloudanzen.com` | After a planned cutover; until then a temporary name such as `app-next.cloudanzen.com` |
| Platform administration | `platform.cloudanzen.com` | After a planned cutover; until then a temporary name such as `platform-next.cloudanzen.com`; staging uses `platform.staging.cloudanzen.com` |

`app.cloudanzen.com` and `platform.cloudanzen.com` serve the live legacy application today (public DNS on 2026-11-18: `app` through the Cloudflare proxy to Vercel, `platform` as a CNAME to Vercel). Moving them is a planned cutover with its own approval, DNS change window, rollback and customer communication. The legacy users of `app.cloudanzen.com` need a new home (their data migrated to GKE, or a different legacy hostname) before it becomes the canary.

The **canary ring** serves the next release digest, ahead of the stable release on `*.app.cloudanzen.com`, to internal and opted-in tenants. It runs in the production namespace against the production database, so every schema change must be expand-and-contract compatible with both the canary and stable versions. Promotion from canary to stable reuses the same digests.

Reserve system names in the tenant registry so no tenant can claim them: at least `app`, `api`, `platform`, `admin`, `console`, `canary`, `staging`, `www`, `auth`, `login`, `status` and `docs`. A wildcard certificate for `*.app.cloudanzen.com` does not cover `app.cloudanzen.com` itself or `*.staging.app.cloudanzen.com`; each needs its own certificate entry.

Serve both the frontend and `/api` through each customer's hostname, with the gateway routing to shared frontend/backend services. Maintain one release per environment by default. Terraform owns the shared wildcard DNS/certificate infrastructure; Argo owns the gateway routes; adding a standard tenant updates application state without a Terraform apply or per-customer Helm release. Validate the selected GatewayClass/Certificate Manager combination for wildcard certificates. See [GKE Gateway guidance](https://docs.cloud.google.com/kubernetes-engine/docs/how-to/deploying-gateways).

Maintain an application-owned tenant/domain registry with:

- Immutable organization ID, environment, canonical normalized hostname, aliases and lifecycle status.
- A unique domain reservation and explicit protection of system/reserved names.
- Authentication mode and future identity-project/tenant mapping; these are references, not secrets.
- Provisioning operation ID and recorded external resource IDs for recovery/retry.

Hostnames may change; organization IDs and historical evidence ownership do not. Preserve retired-name reservations/tombstones to prevent immediate takeover. Custom customer-owned domains need ownership verification and certificate lifecycle work and are deferred. Public Trust Center domains remain a separate access surface and are not accepted as authenticated workspace hosts automatically.

## Access invariant

Resolve the host at the trusted edge and backend. Allow only registered active hosts. Do not trust arbitrary `X-Forwarded-Host`, `X-Organization-ID`, request-body tenant IDs or user-supplied redirects. Strip/overwrite forwarded headers at the edge, configure trusted proxies narrowly and prevent bypass through direct origins or the old shared API login route.

For every tenant request, require the host's organization to match the verified identity's permitted organization and the current application session context. Under the future provider, verify the expected project/issuer/audience and authentication tenant too. Disabled identities, suspended organizations and removed memberships are denied even if a token has not expired. Keep database/RLS authorization in place.

A user from Acme cannot establish a CloudAnzen session on Contoso's host or replay an Acme session there. Reject the request; never silently switch or create membership. Identity-provider login may legitimately visit Google's domain; the enforceable promise is that a CloudAnzen workspace session and data access are bound to the registered customer host. DNS, CORS or Firebase authorized-domain configuration alone cannot enforce this promise.

Use host-only Secure/HttpOnly application cookies (a `__Host-` cookie where applicable), explicit CSRF controls and validated callback destinations. Do not use a parent-domain session cookie. Sibling subdomains being same-site is not a CSRF defense. Tenant hosts must reject platform-admin APIs and platform sessions; platform administration keeps its own audience, permissions and audit trail. Do not introduce implicit cross-tenant support access.

Browser traffic uses the tenant host. Webhooks, agents and other non-browser endpoints require separately defined authentication/tenant-binding rules; retain legitimate integration callbacks without creating an interactive-login bypass.

OAuth callbacks use one fixed callback host per environment, not tenant hosts. GitHub OAuth Apps accept a single callback URL (and its subpaths), and the current Google sign-in and integration callbacks are single configured URLs. The flow starts on the tenant host with signed, server-stored, single-use state that records the organization, initiating session and registered return host; the callback validates that state, creates no session on its own host and redirects only to the recorded host. The current GitHub integration state is unsigned base64 (backend `src/modules/integrations/providers/integration-oauth-routes.ts:80-82`), so signed state is a prerequisite for host-bound sessions.

Cloudflare serves DNS only in the first milestone; the GKE Gateway terminates TLS and is the only trusted proxy. Enabling Cloudflare proxying later is a separate decision because it changes trusted-proxy sources, client-IP and forwarded-header handling, and certificate validation.

## Onboarding ownership and lifecycle

The authorized platform service starts a durable provisioning operation. A narrowly privileged worker, not an unrestricted public request handler, performs external identity provisioning. A proposed sequence is:

`REQUESTED → DOMAIN_RESERVED → ORGANIZATION_CREATED → IDENTITY_READY → CONFIGURED → ADMIN_INVITED → ACTIVE`

Record each completed step, error and retry. `IDENTITY_READY` uses the selected organization's auth mode; it must not pretend a Firebase tenant exists before migration. Invite acceptance and identity verification are separate from sending an email. Activate only after the required setup and administrator checks pass. Failed or partial tenants remain inaccessible.

Reserve names atomically, make local seeding idempotent and record remote IDs before advancing. Where a provider call has an ambiguous outcome, reconcile it before retrying creation; flag uncertainty for an operator rather than duplicating or deleting resources blindly. Provide status, retry and controlled cancellation in the platform UI, with an audit record.

Seed authorized framework entitlements/templates without assigning unearned compliance passes. Customers authorize their own integrations and confirm scope. Suspension denies new sessions and revokes/invalidates existing application access; offboarding follows retention and explicit deletion policy.

## Alternatives and acceptance

Dedicated clusters per standard tenant are deferred. A shared login URL with only frontend tenant filtering fails the access requirement. Email suffix-based automatic membership is rejected.

Before customer subdomains go live, verify correct-host login, wrong-host token replay, unknown/suspended hosts, forwarded-header spoofing, direct-origin/shared-URL bypass, platform/tenant boundary, CSRF, safe redirects, browser tabs for different tenants, duplicate onboarding, interrupted external provisioning and domain retirement. These are later rollout gates; the initial GCP milestone only needs the configuration/routing contracts and synthetic-host proof that avoid redesign.
