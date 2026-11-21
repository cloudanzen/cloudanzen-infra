# One environment's slice of the shared Gateway edge (ADR-0004, ADR-0006):
# a Google-managed wildcard certificate for *.<base_domain>, its entry in the
# shared certificate map, and DNS-only Cloudflare records (no proxying in M1).
# Google resources live in the cluster project because certificate map
# entries must sit next to the map the Gateway uses.

locals {
  wildcard = "*.${var.base_domain}"
  name     = "cloudanzen-${var.environment}"
  comment  = "cloudanzen-infra Terraform (${var.environment} foundation)"
}

data "google_compute_global_address" "gateway" {
  project = var.cluster_project_id
  name    = var.gateway_address_name
}

data "cloudflare_zone" "this" {
  filter = {
    name = var.zone_name
  }
}

# Wildcard certificates need DNS authorization: Certificate Manager gives a
# CNAME for _acme-challenge.<base_domain> that stays in place for renewals.
resource "google_certificate_manager_dns_authorization" "this" {
  project     = var.cluster_project_id
  name        = local.name
  description = "DNS authorization for ${local.wildcard}"
  domain      = var.base_domain
  labels      = var.labels
}

resource "google_certificate_manager_certificate" "this" {
  project     = var.cluster_project_id
  name        = local.name
  description = "Wildcard certificate for ${local.wildcard}"
  labels      = var.labels

  managed {
    domains            = [local.wildcard]
    dns_authorizations = [google_certificate_manager_dns_authorization.this.id]
  }
}

resource "google_certificate_manager_certificate_map_entry" "this" {
  project      = var.cluster_project_id
  name         = local.name
  description  = "Serves ${local.wildcard}"
  map          = var.certificate_map
  hostname     = local.wildcard
  certificates = [google_certificate_manager_certificate.this.id]
  labels       = var.labels
}

resource "cloudflare_dns_record" "acme_challenge" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = trimsuffix(google_certificate_manager_dns_authorization.this.dns_resource_record[0].name, ".")
  type    = google_certificate_manager_dns_authorization.this.dns_resource_record[0].type
  content = trimsuffix(google_certificate_manager_dns_authorization.this.dns_resource_record[0].data, ".")
  ttl     = 300
  proxied = false
  comment = local.comment
}

resource "cloudflare_dns_record" "host" {
  for_each = toset(var.hostnames)

  zone_id = data.cloudflare_zone.this.zone_id
  name    = "${each.key}.${var.base_domain}"
  type    = "A"
  content = data.google_compute_global_address.gateway.address
  ttl     = 300
  proxied = false
  comment = local.comment
}
