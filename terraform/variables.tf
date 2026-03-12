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
