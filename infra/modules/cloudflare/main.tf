terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

resource "cloudflare_record" "this" {
  for_each = var.records

  zone_id = var.zone_id

  name    = each.value.name
  value   = each.value.value
  type    = each.value.type
  ttl     = each.value.ttl
  proxied = each.value.proxied

  comment = "Managed by Terraform — ${var.env}"
}
