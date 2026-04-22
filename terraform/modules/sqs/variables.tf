variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente"
  type        = string
}

variable "raw_bucket_arn" {
  description = "ARN del bucket S3 raw"
  type        = string
}

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
}
