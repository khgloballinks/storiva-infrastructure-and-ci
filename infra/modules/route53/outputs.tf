output "record_ids" {
  description = "Cloudflare record IDs"
  value       = { for k, v in cloudflare_record.records : k => v.id }
}
