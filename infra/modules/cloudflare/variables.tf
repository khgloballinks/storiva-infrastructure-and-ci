variable "env" {
  description = "Environment name (prod, staging, dev)"
  type        = string
}

variable "zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
}

variable "records" {
  description = "Map of DNS records to create"
  type = map(object({
    name    = string
    value   = string
    type    = string   # A, AAAA, CNAME, TXT, MX, etc.
    ttl     = number
    proxied = bool
  }))
}