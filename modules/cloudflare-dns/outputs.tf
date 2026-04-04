output "record_ids" {
  description = "Map of record name to record ID"
  value       = { for k, v in cloudflare_record.records : k => v.id }
}
