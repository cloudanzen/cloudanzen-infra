output "hostnames" {
  description = "Fully qualified hostnames pointed at the Gateway."
  value       = sort([for r in cloudflare_dns_record.host : r.name])
}

output "certificate" {
  description = "Certificate Manager certificate ID."
  value       = google_certificate_manager_certificate.this.id
}

output "gateway_address" {
  description = "Address the records point to."
  value       = data.google_compute_global_address.gateway.address
}
