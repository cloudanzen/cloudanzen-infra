terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 4.0"
    }
  }
}

resource "cloudflare_r2_bucket" "this" {
  account_id = var.account_id
  name       = var.bucket_name
  location   = var.location
}

# API token for GitHub Actions to upload backups
resource "cloudflare_api_token" "r2_rw" {
  name = "${var.bucket_name}-rw"

  policy {
    permission_groups = var.r2_permission_group_ids
    resources = {
      "com.cloudflare.edge.r2.bucket.${cloudflare_r2_bucket.this.id}" = "*"
    }
  }
}
