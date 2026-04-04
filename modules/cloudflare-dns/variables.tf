variable "zone_id" {
  description = "Cloudflare zone ID for the domain"
  type        = string
}

variable "records" {
  description = "DNS records to create"
  type = map(object({
    name    = string
    type    = string
    value   = string
    proxied = optional(bool, true)
    ttl     = optional(number, 1) # 1 = automatic
  }))
  default = {}
}
