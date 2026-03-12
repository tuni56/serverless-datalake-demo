variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente"
  type        = string
}

variable "athena_results_bucket_name" {
  description = "Nombre del bucket S3 para resultados de Athena"
  type        = string
}

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
}
