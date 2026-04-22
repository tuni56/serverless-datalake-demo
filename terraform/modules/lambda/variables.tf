variable "project_name" { type = string }
variable "environment"  { type = string }
variable "glue_job_name" { type = string }
variable "sqs_queue_arn" { type = string }
variable "lambda_role_arn" { type = string }
variable "tags" { type = map(string) }
