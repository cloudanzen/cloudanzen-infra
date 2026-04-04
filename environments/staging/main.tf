# ── Staging Environment ──────────────────────────────────────────────────────
# Railway project: vinmnit159/sublime-courage (already created)
# This config manages the Vercel staging project and Cloudflare DNS records.
# Railway services are managed via Railway CLI in the CD pipeline for now,
# since the Railway Terraform provider has limited support for linking
# existing projects. We'll import them once the provider matures.

# ── Vercel: Frontend Staging ─────────────────────────────────────────────────

module "frontend_staging" {
  source = "../../modules/vercel-project"

  project_name     = "manzen-staging"
  framework        = "vite"
  git_repo         = "vinmnit159/Cloudanzen-frontend"
  build_command    = "npm run build"
  output_directory = "dist"
  domains          = ["staging.app.cloudanzen.com"]

  env_vars = {
    VITE_API_URL = {
      value  = "https://staging-api.cloudanzen.com"
      target = ["production", "preview"]
    }
    VITE_SENTRY_DSN = {
      value  = var.sentry_dsn_frontend
      target = ["production", "preview"]
    }
  }
}

# ── Cloudflare DNS: Staging Records ──────────────────────────────────────────

module "staging_dns" {
  source = "../../modules/cloudflare-dns"

  zone_id = var.cloudflare_zone_id

  records = {
    staging-app = {
      name    = "staging.app"
      type    = "CNAME"
      value   = "cname.vercel-dns.com"
      proxied = false # Vercel needs direct CNAME
    }
    # staging-api CNAME will be added once Railway provides the domain
    # For now, Railway custom domain is configured via Railway dashboard
  }
}

# ── GitHub: Repository Settings ──────────────────────────────────────────────

module "backend_repo" {
  source = "../../modules/github-repo"

  repository             = "Cloudanzen-backend"
  required_status_checks = ["Build, Lint, and Test"]
}

module "frontend_repo" {
  source = "../../modules/github-repo"

  repository             = "Cloudanzen-frontend"
  required_status_checks = ["checks"]
}

module "marketing_repo" {
  source = "../../modules/github-repo"

  repository             = "cloudanzen"
  required_status_checks = ["Lint, Typecheck, Build"]
}

module "mdm_agent_repo" {
  source = "../../modules/github-repo"

  repository             = "manzen-mdm-agent"
  required_status_checks = ["Vet, Test, Build"]
}
