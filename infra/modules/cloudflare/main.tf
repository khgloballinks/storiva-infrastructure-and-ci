terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

resource "cloudflare_record" "this" {
  zone_id = var.zone_id
  name    = var.record_name
  value   = var.ip_address
  type    = "A"
  ttl     = var.ttl
  proxied = var.proxied

  comment = "Managed by Terraform — storiva ${var.env}"
}