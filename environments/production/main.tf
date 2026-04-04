# ── Production Environment ───────────────────────────────────────────────────
# Vercel projects and Cloudflare DNS for production.
# Railway production services are managed via Railway dashboard + CLI deploys.

# ── Vercel: Frontend Production ──────────────────────────────────────────────

module "frontend_production" {
  source = "../../modules/vercel-project"

  project_name     = "manzen"
  framework        = "vite"
  git_repo         = "vinmnit159/Cloudanzen-frontend"
  build_command    = "npm run build"
  output_directory = "dist"
  domains          = ["app.cloudanzen.com"]

  env_vars = {
    VITE_API_URL = {
      value  = "https://api.cloudanzen.com"
      target = ["production"]
    }
    VITE_SENTRY_DSN = {
      value  = var.sentry_dsn_frontend
      target = ["production"]
    }
  }
}

# ── Vercel: Marketing Site ───────────────────────────────────────────────────

module "marketing_production" {
  source = "../../modules/vercel-project"

  project_name     = "cloudanzen"
  framework        = "nextjs"
  git_repo         = "vinmnit159/cloudanzen"
  build_command    = "npm run build"
  output_directory = ".next"
  domains          = ["www.cloudanzen.com"]
}

# ── Cloudflare DNS: Production Records ───────────────────────────────────────

module "production_dns" {
  source = "../../modules/cloudflare-dns"

  zone_id = var.cloudflare_zone_id

  records = {
    app = {
      name    = "app"
      type    = "CNAME"
      value   = "cname.vercel-dns.com"
      proxied = false
    }
    www = {
      name    = "www"
      type    = "CNAME"
      value   = "cname.vercel-dns.com"
      proxied = false
    }
    # api.cloudanzen.com is managed by Railway custom domain
    # The CNAME was already created manually and should be imported
  }
}
