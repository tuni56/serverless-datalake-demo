output "raw_bucket_name" {
  description = "Nombre del bucket S3 para datos raw"
  value       = module.s3.raw_bucket_name
}

output "curated_bucket_name" {
  description = "Nombre del bucket S3 para datos curated"
  value       = module.s3.curated_bucket_name
}

output "glue_crawler_name" {
  description = "Nombre del Glue Crawler"
  value       = module.glue.crawler_name
}

output "glue_job_name" {
  description = "Nombre del Glue ETL Job"
  value       = module.glue.job_name
}

output "athena_workgroup" {
  description = "Nombre del Athena Workgroup"
  value       = module.athena.workgroup_name
}

output "glue_database_name" {
  description = "Nombre de la base de datos en Glue Catalog"
  value       = module.glue.database_name
}
