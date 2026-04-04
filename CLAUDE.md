# CloudAnzen Infrastructure

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
| `terraform.yml` | Push to main | `terraform apply staging` (auto) → `terraform apply production` (manual approval) |

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
- All secrets go in Terraform Cloud workspace variables, never in .tf files
- DNS changes affect all services — verify domains after apply
- Changes here are typically Infra/DevOps classification in the lifecycle
- Always run `terraform fmt` before committing
- State is managed remotely — never commit .tfstate files
