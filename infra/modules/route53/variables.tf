variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID"
  type        = string
}

variable "dns_records" {
  description = "Map of DNS records to create"
  type = map(object({
    name    = string
    type    = string
    value   = string
    proxied = bool
  }))
}
