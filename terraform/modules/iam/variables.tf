variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente"
  type        = string
}

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
}
