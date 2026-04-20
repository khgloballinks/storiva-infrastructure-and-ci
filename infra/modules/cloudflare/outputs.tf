output "record_ids" {
  description = "Map of Cloudflare record IDs"
  value       = { for k, v in cloudflare_record.this : k => v.id }
}

output "record_hostnames" {
  description = "Map of Cloudflare hostnames"
  value       = { for k, v in cloudflare_record.this : k => v.hostname }
}