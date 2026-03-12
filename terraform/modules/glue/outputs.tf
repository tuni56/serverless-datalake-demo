output "database_name" {
  description = "Nombre de la base de datos Glue"
  value       = aws_glue_catalog_database.ecommerce.name
}

output "crawler_name" {
  description = "Nombre del Glue Crawler raw"
  value       = aws_glue_crawler.raw.name
}

output "curated_crawler_name" {
  description = "Nombre del Glue Crawler curated"
  value       = aws_glue_crawler.curated.name
}

output "job_name" {
  description = "Nombre del Glue Job"
  value       = aws_glue_job.transform.name
}
