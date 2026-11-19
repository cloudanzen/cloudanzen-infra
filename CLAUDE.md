# CloudAnzen Infrastructure

## New GCP platform planning

Read `docs/iac-gitops-implementation-plan.md` and `docs/adr/README.md` for the target architecture, implementation gates and deferred tenant/Firebase milestones. They supersede the external Claude planning brief. The existing stack and roots below remain the legacy implementation; do not repurpose their state or change their release behavior as part of new GCP work.

## Stack
- **Tool**: Terraform
- **State backend**: Terraform Cloud (`app.terraform.io/app/cloudanzen`)
- **Providers**: Railway, Vercel, Cloudflare, GitHub

## Structure
```
environments/
  staging/     — Staging environment config
  production/  — Production environment config
modules/
  railway-project/  — Railway services, env vars, plugins, domains
  vercel-project/   — Vercel projects, domains, env vars, build settings
  github-repo/      — Branch protection, environments, required checks
  cloudflare-dns/   — DNS records for all domains
```

## CI Workflows
| Workflow | Trigger | Steps |
|----------|---------|-------|
| `terraform.yml` | PR to main | `terraform plan` (posted as PR comment) |
| `terraform.yml` | Push to main | `terraform apply staging` → `terraform apply production`; actual GitHub environment approval rules must be verified |

## Key Commands
| Command | Purpose |
|---------|---------|
| `terraform init` | Initialize providers |
| `terraform plan` | Preview changes |
| `terraform apply` | Apply changes |
| `terraform fmt` | Format .tf files |
| `terraform validate` | Validate config |

## Repo-Specific Rules
- Never apply production without staging first
- Legacy automation credentials go in protected Terraform Cloud workspace variables, never committed .tf/.tfvars files. For the planned GCP platform, follow ADR-0003: application secret values live in Secret Manager and reach workloads through ESO; Terraform manages containers/IAM only. Necessary non-federated automation credentials use the selected protected execution store.
- DNS changes affect all services — verify domains after apply
- Changes here are typically Infra/DevOps classification in the lifecycle
- Always run `terraform fmt` before committing
- State is managed remotely — never commit .tfstate files
