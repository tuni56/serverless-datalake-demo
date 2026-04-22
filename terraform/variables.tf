variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "ecommerce-datalake"
}

variable "environment" {
  description = "Ambiente (dev, prod)"
  type        = string
}

variable "aws_region" {
  description = "Region de AWS"
  type        = string
  default     = "us-east-2"
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default     = {}
}

variable "alert_email" {
  description = "Email para recibir alertas de CloudWatch (SNS)"
  type        = string
  default     = "alerts@example.com"
}

variable "quicksight_user" {
  description = "QuickSight username para permisos del data source (e.g. Admin/rocio)"
  type        = string
  default     = ""
}
