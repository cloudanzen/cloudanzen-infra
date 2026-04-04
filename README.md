# CloudAnzen Infrastructure

Terraform IaC for the CloudAnzen platform. Manages Vercel projects, Cloudflare DNS, and GitHub repository settings.

## Structure

```
environments/
  staging/       # Staging environment (auto-applied on merge to main)
  production/    # Production environment (applied after staging succeeds)
modules/
  railway-project/   # Railway project + services (future use)
  vercel-project/    # Vercel project, domains, env vars
  cloudflare-dns/    # Cloudflare DNS records
  github-repo/       # GitHub branch protection + settings
```

## Setup

### Prerequisites

1. [Terraform CLI](https://developer.hashicorp.com/terraform/install) >= 1.5
2. [Terraform Cloud](https://app.terraform.io) account with org `cloudanzen`

### Terraform Cloud Workspaces

Create two workspaces in Terraform Cloud: `staging` and `production`.

Set these variables in each workspace (mark as sensitive):

| Variable | Type | Description |
|----------|------|-------------|
| `railway_token` | Terraform | Railway API token (staging only) |
| `vercel_token` | Terraform | Vercel API token |
| `cloudflare_api_token` | Terraform | Cloudflare API token |
| `cloudflare_zone_id` | Terraform | Cloudflare zone ID for cloudanzen.com |
| `sentry_dsn_backend` | Terraform | Sentry DSN for backend |
| `sentry_dsn_frontend` | Terraform | Sentry DSN for frontend |

### GitHub Actions Secret

Set `TF_API_TOKEN` as a repository secret — this is a Terraform Cloud API token.

## Workflow

- **PR to main**: `terraform plan` runs for both environments, results posted as PR comment
- **Merge to main**: `terraform apply` runs staging first, then production
