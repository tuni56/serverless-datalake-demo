variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "athena_workgroup_name" {
  type = string
}

variable "curated_bucket_arn" {
  type = string
}

variable "athena_results_bucket_name" {
  type = string
}

variable "glue_database_name" {
  type = string
}

variable "quicksight_user" {
  description = "QuickSight username (e.g. Admin/rocio)"
  type        = string
}

variable "tags" {
  type = map(string)
}
