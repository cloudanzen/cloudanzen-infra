terraform {
  required_providers {
    vercel = {
      source  = "vercel/vercel"
      version = "~> 2.0"
    }
  }
}

resource "vercel_project" "this" {
  name      = var.project_name
  framework = var.framework

  git_repository = {
    type = "github"
    repo = var.git_repo
  }

  build_command    = var.build_command
  output_directory = var.output_directory
}

resource "vercel_project_domain" "domains" {
  for_each   = toset(var.domains)
  project_id = vercel_project.this.id
  domain     = each.value
}

resource "vercel_project_environment_variable" "env_vars" {
  for_each   = var.env_vars
  project_id = vercel_project.this.id
  key        = each.key
  value      = each.value.value
  target     = each.value.target
}
