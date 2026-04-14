resource "cloudflare_record" "records" {
  for_each = var.dns_records

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  value   = each.value.value
  type    = each.value.type
  proxied = each.value.proxied

  tags = {
    Environment = var.environment
  }
}
