terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region

  default_labels = {
    managed-by = "terraform"
    system     = "cloudanzen"
  }
}

# Reads CLOUDFLARE_API_TOKEN from the environment (HCP variable set
# cloudflare-dns, sensitive). The token never becomes a Terraform variable,
# so it is not in plans or state.
provider "cloudflare" {}
