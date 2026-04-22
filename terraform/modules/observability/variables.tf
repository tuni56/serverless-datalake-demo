variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente"
  type        = string
}

variable "glue_job_name" {
  description = "Nombre del Glue ETL Job"
  type        = string
}

variable "dlq_name" {
  description = "Nombre de la Dead Letter Queue"
  type        = string
}

variable "alert_email" {
  description = "Email para recibir alertas de CloudWatch"
  type        = string
}

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
}
