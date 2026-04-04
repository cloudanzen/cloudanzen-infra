terraform {
  cloud {
    organization = "cloudanzen"
    workspaces {
      name = "staging"
    }
  }

  required_version = ">= 1.5"

  required_providers {
    railway = {
      source  = "terraform-community/railway"
      version = "~> 0.4"
    }
    vercel = {
      source  = "vercel/vercel"
      version = "~> 2.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "railway" {
  token = var.railway_token
}

provider "vercel" {
  api_token = var.vercel_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "github" {
  owner = "vinmnit159"
}
