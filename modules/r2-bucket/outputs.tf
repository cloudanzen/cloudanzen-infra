output "bucket_name" {
  description = "The name of the R2 bucket"
  value       = cloudflare_r2_bucket.this.name
}

output "bucket_id" {
  description = "The ID of the R2 bucket"
  value       = cloudflare_r2_bucket.this.id
}

output "s3_endpoint" {
  description = "S3-compatible endpoint URL for the bucket"
  value       = "https://${var.account_id}.r2.cloudflarestorage.com"
}
