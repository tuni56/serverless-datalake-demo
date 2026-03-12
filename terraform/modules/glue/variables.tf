variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente"
  type        = string
}

variable "raw_bucket_name" {
  description = "Nombre del bucket S3 raw"
  type        = string
}

variable "curated_bucket_name" {
  description = "Nombre del bucket S3 curated"
  type        = string
}

variable "scripts_bucket_name" {
  description = "Nombre del bucket S3 scripts"
  type        = string
}

variable "glue_crawler_role_arn" {
  description = "ARN del rol IAM para Glue Crawler"
  type        = string
}

variable "glue_job_role_arn" {
  description = "ARN del rol IAM para Glue Job"
  type        = string
}

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
}
