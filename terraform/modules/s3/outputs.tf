output "raw_bucket_name" {
  description = "Nombre del bucket S3 raw"
  value       = aws_s3_bucket.raw.id
}

output "raw_bucket_arn" {
  description = "ARN del bucket S3 raw"
  value       = aws_s3_bucket.raw.arn
}

output "curated_bucket_name" {
  description = "Nombre del bucket S3 curated"
  value       = aws_s3_bucket.curated.id
}

output "curated_bucket_arn" {
  description = "ARN del bucket S3 curated"
  value       = aws_s3_bucket.curated.arn
}

output "scripts_bucket_name" {
  description = "Nombre del bucket S3 scripts"
  value       = aws_s3_bucket.scripts.id
}

output "athena_results_bucket_name" {
  description = "Nombre del bucket S3 para resultados de Athena"
  value       = aws_s3_bucket.athena_results.id
}
