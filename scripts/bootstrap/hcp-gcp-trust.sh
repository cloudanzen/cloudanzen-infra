#!/usr/bin/env bash
# One-time bootstrap (ADR-0002): lets HCP Terraform authenticate to GCP with
# short-lived dynamic credentials, so no service-account key ever exists.
#
# Run by a GCP organization administrator with gcloud already authenticated:
#
#   ORG_ID=<org id> BILLING_ACCOUNT=<billing account id> \
#     scripts/bootstrap/hcp-gcp-trust.sh
#
# Optional overrides: PROJECT_ID (default cloudanzen-gke), HCP_ORG (default
# cloudanzen), WORKSPACES (space-separated). The script is idempotent: it
# creates what is missing and re-applies IAM bindings. It prints only
# non-secret identifiers. Nothing here creates a key or reads a secret.

set -euo pipefail

: "${ORG_ID:?Set ORG_ID to the GCP organization ID}"
: "${BILLING_ACCOUNT:?Set BILLING_ACCOUNT to the billing account ID}"
PROJECT_ID="${PROJECT_ID:-cloudanzen-gke}"
HCP_ORG="${HCP_ORG:-cloudanzen}"
WORKSPACES="${WORKSPACES:-gcp-org-projects gcp-platform-foundation gcp-platform-bootstrap gcp-staging-foundation gcp-prod-foundation}"
# Environment projects that already exist (for example created in the
# console). Projects created by Terraform make the apply identity owner
# automatically; pre-existing ones need the grant below.
ENV_PROJECTS="${ENV_PROJECTS:-cloudanzen-staging cloudanzen-prod}"

POOL_ID="hcp-terraform"
PROVIDER_ID="hcp-terraform"
PLAN_SA_ID="terraform-plan"
APPLY_SA_ID="terraform-apply"

PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"
PLAN_SA="${PLAN_SA_ID}@${PROJECT_ID}.iam.gserviceaccount.com"
APPLY_SA="${APPLY_SA_ID}@${PROJECT_ID}.iam.gserviceaccount.com"
POOL_NAME="projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}"

echo "==> Enabling bootstrap APIs on ${PROJECT_ID}"
gcloud services enable --project "$PROJECT_ID" \
  iam.googleapis.com iamcredentials.googleapis.com sts.googleapis.com \
  cloudresourcemanager.googleapis.com serviceusage.googleapis.com \
  cloudbilling.googleapis.com

echo "==> Workload identity pool and HCP Terraform provider"
if ! gcloud iam workload-identity-pools describe "$POOL_ID" \
  --project "$PROJECT_ID" --location global >/dev/null 2>&1; then
  gcloud iam workload-identity-pools create "$POOL_ID" \
    --project "$PROJECT_ID" --location global \
    --display-name "HCP Terraform"
fi

# workspace_phase lets each workspace's plan and apply phases map to
# different service accounts. Only tokens from the HCP organization are
# accepted.
MAPPING="google.subject=assertion.sub"
MAPPING+=",attribute.terraform_organization_name=assertion.terraform_organization_name"
MAPPING+=",attribute.terraform_workspace_name=assertion.terraform_workspace_name"
MAPPING+=",attribute.terraform_run_phase=assertion.terraform_run_phase"
MAPPING+=",attribute.workspace_phase=assertion.terraform_workspace_name + ':' + assertion.terraform_run_phase"
CONDITION="assertion.terraform_organization_name == '${HCP_ORG}'"

if gcloud iam workload-identity-pools providers describe "$PROVIDER_ID" \
  --project "$PROJECT_ID" --location global --workload-identity-pool "$POOL_ID" >/dev/null 2>&1; then
  gcloud iam workload-identity-pools providers update-oidc "$PROVIDER_ID" \
    --project "$PROJECT_ID" --location global --workload-identity-pool "$POOL_ID" \
    --issuer-uri "https://app.terraform.io" \
    --attribute-mapping "$MAPPING" --attribute-condition "$CONDITION"
else
  gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_ID" \
    --project "$PROJECT_ID" --location global --workload-identity-pool "$POOL_ID" \
    --display-name "HCP Terraform (${HCP_ORG})" \
    --issuer-uri "https://app.terraform.io" \
    --attribute-mapping "$MAPPING" --attribute-condition "$CONDITION"
fi

echo "==> Service accounts"
for sa in "$PLAN_SA_ID" "$APPLY_SA_ID"; do
  if ! gcloud iam service-accounts describe "${sa}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --project "$PROJECT_ID" >/dev/null 2>&1; then
    gcloud iam service-accounts create "$sa" --project "$PROJECT_ID" \
      --display-name "HCP Terraform ${sa#terraform-}"
  fi
done

echo "==> Bind each workspace phase to its service account"
for ws in $WORKSPACES; do
  gcloud iam service-accounts add-iam-policy-binding "$PLAN_SA" --project "$PROJECT_ID" \
    --role roles/iam.workloadIdentityUser \
    --member "principalSet://iam.googleapis.com/${POOL_NAME}/attribute.workspace_phase/${ws}:plan" \
    --condition=None >/dev/null
  gcloud iam service-accounts add-iam-policy-binding "$APPLY_SA" --project "$PROJECT_ID" \
    --role roles/iam.workloadIdentityUser \
    --member "principalSet://iam.googleapis.com/${POOL_NAME}/attribute.workspace_phase/${ws}:apply" \
    --condition=None >/dev/null
done

echo "==> Roles for the plan identity (read-only)"
for role in roles/viewer roles/iam.securityReviewer; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member "serviceAccount:${PLAN_SA}" --role "$role" --condition=None >/dev/null
done
gcloud organizations add-iam-policy-binding "$ORG_ID" \
  --member "serviceAccount:${PLAN_SA}" --role roles/browser --condition=None >/dev/null
gcloud billing accounts add-iam-policy-binding "$BILLING_ACCOUNT" \
  --member "serviceAccount:${PLAN_SA}" --role roles/billing.viewer >/dev/null

echo "==> Roles for the apply identity"
# Owner on the shared cluster project is needed to manage IAM, services and
# the cluster there. Environment projects created by the gcp-org-projects
# workspace grant this identity ownership as their creator.
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member "serviceAccount:${APPLY_SA}" --role roles/owner --condition=None >/dev/null
gcloud organizations add-iam-policy-binding "$ORG_ID" \
  --member "serviceAccount:${APPLY_SA}" --role roles/resourcemanager.projectCreator \
  --condition=None >/dev/null
gcloud billing accounts add-iam-policy-binding "$BILLING_ACCOUNT" \
  --member "serviceAccount:${APPLY_SA}" --role roles/billing.user >/dev/null
for env_project in $ENV_PROJECTS; do
  if gcloud projects describe "$env_project" >/dev/null 2>&1; then
    gcloud projects add-iam-policy-binding "$env_project" \
      --member "serviceAccount:${APPLY_SA}" --role roles/owner --condition=None >/dev/null
    echo "    apply identity is owner of existing project ${env_project}"
  fi
done

cat <<EOF

Done. Set these environment variables on each HCP Terraform workspace
(${WORKSPACES}):

  TFC_GCP_PROVIDER_AUTH                = true
  TFC_GCP_WORKLOAD_PROVIDER_NAME       = ${POOL_NAME}/providers/${PROVIDER_ID}
  TFC_GCP_PLAN_SERVICE_ACCOUNT_EMAIL   = ${PLAN_SA}
  TFC_GCP_APPLY_SERVICE_ACCOUNT_EMAIL  = ${APPLY_SA}

None of these values are secret.
EOF
