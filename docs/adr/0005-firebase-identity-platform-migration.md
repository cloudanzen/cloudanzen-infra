# ADR-0005: Future Firebase authentication and application authorization

- Date: 2026-11-18
- Status: Accepted migration direction; detailed provider configuration and cutover pending validation
- Plan: [IaC/GitOps implementation plan](../iac-gitops-implementation-plan.md)
- Related: [Tenant hosts/onboarding](0004-tenant-hostnames-and-onboarding.md)

## Context

CloudAnzen currently issues its own tenant/platform sessions and stores application users, roles and organization relationships. The product owner wants to move authentication to Google Firebase eventually, while retaining a shared backend and organization-specific login hosts.

## Decision

Target Firebase Authentication with Google Cloud Identity Platform multi-tenancy. The design default is one authentication tenant per CloudAnzen organization inside a separate identity project for each deployment environment; this may be the corresponding GCP environment project. Do not create a Firebase/GCP project or Kubernetes deployment per customer by default. Confirm provider capabilities, quotas, costs and customer SSO needs before implementation.

Identity Platform supports tenant-specific users and login providers, including SAML/OIDC. It does not isolate CloudAnzen's Postgres rows. CloudAnzen retains organization membership, roles, entitlement checks, auditor scope, suspension, session invalidation and database authorization. See [multi-tenancy](https://docs.cloud.google.com/identity-platform/docs/multi-tenancy) and [Firebase/Identity Platform comparison](https://docs.cloud.google.com/identity-platform/docs/product-comparison).

Separate identity verification behind an application interface that returns a verified external identity. An authorization layer resolves that identity to existing internal user/organization IDs and current permissions. Existing business routes consume that internal actor rather than depending directly on Firebase SDK claims or trusting a client-supplied organization ID.

Create an explicit identity-link record keyed by provider, identity project/issuer, authentication tenant and provider user ID. Preserve internal user IDs and their evidence/audit relationships. Email alone is not an identity-link key. The current globally unique `User.email` and single-organization relationship must be reviewed for same-email accounts, external auditors and platform administrators; do not silently merge or grant cross-organization access.

## Login and session contract

1. Resolve the registered host and organization on the server. Return only minimal public login configuration for an active workspace.
2. Initialize the Firebase client with the intended tenant before each login flow/reload; do not assume switching client `tenantId` replaces an already signed-in user.
3. Verify the token for the expected project and tenant using the supported tenant-aware verifier, including the selected revocation/disabled-user policy.
4. Resolve the verified identity link and active organization membership, then issue/validate a host-bound application session under ADR-0004.
5. Preserve current application role-change, removal and session-version invalidation semantics; token expiry alone must not become the access-revocation policy.

Google documents tenant-specific token verification and tenant/user administration through its Admin SDK. Project-level signature verification alone is not sufficient to enforce the selected tenant. See [tenant administration and verification](https://docs.cloud.google.com/identity-platform/docs/multi-tenancy-managing-tenants).

Choose and test the final browser-session mechanism during the spike: a CloudAnzen server session after verified Firebase login, or a supported tenant-aware provider session mechanism. Do not promise compatibility without testing the selected SDK. Platform administrators use a separately restricted identity policy and application audience, never an implicit customer-tenant bypass.

The web Firebase configuration and tenant ID are public identifiers. They are not authorization credentials. Server provisioning credentials and OAuth client secrets stay out of the frontend and follow [ADR-0003](0003-secret-authority-and-delivery.md). Use least-privilege GCP workload identity for backend administration where supported; avoid service-account JSON keys.

## Callback and provisioning validation

Exact auth-handler hosting, authorized domains, redirect URIs and email-action URLs remain a spike decision. Do not assume wildcard DNS authorizes arbitrary Firebase redirects. Tenant domain/redirect settings can inherit from the parent project, and provider-management coverage differs by API. Record any unavoidable account-owner configuration rather than claiming completely automatic setup. See [tenant settings](https://docs.cloud.google.com/identity-platform/docs/multi-tenancy-managing-tenants).

Choose a supported custom-handler/proxy or central callback design, validate state/nonce and exact return destinations, and prove it works in browsers restricting third-party storage. A central callback must establish the application session only on the correct customer host; it must not pass reusable tokens in URLs. See [Firebase redirect guidance](https://firebase.google.com/docs/auth/web/redirect-best-practices).

The onboarding worker owns customer authentication tenants; Terraform owns project-level APIs, IAM and shared provider foundation. Do not let both manage the same customer tenant/provider object. Per-tenant SSO secrets need scoped application-managed storage and lifecycle, not a Terraform resource per customer.

## Migration and rollback

Keep the existing authentication behavior during the initial GCP milestone. The later migration must inventory password hashes, Google identities, verification state, MFA enrollment/recovery, invitations and active sessions. Validate supported import or choose explicit re-enrollment/reset; preserve internal identifiers. Rehearse on synthetic users before migrating real accounts.

Use explicit per-organization cutover status. A migrated organization must not fall back silently to legacy credentials if Firebase verification fails. Revoke legacy access as required, test recovery and support procedures, and define rollback around password/MFA/session changes; changing an environment flag is not a safe universal rollback.

## Alternatives, costs and gates

A single shared Firebase user pool with application memberships is feasible but is not the design default for independently configured customer authentication. A provider migration is not required merely to support customer subdomains; domain enforcement can be implemented with current authentication first. Moving to Firebase does not require moving Postgres, business APIs or frontend hosting to Firebase.

Estimate Identity Platform usage by authentication method/active users and relevant SMS/MFA charges; assess SSO, tenant and domain limits before onboarding scale commitments. See [pricing](https://cloud.google.com/identity-platform/pricing).

Required evidence includes tenant-aware login and replay rejection, project/environment mismatch, verified account linking, invitation/reset flows, browser redirects, MFA/recovery, disablement/revocation, retained application permissions, audit continuity and migration rollback. Exact callback strategy, multi-organization identity policy and cost approval remain open; this ADR does not authorize live migration.
