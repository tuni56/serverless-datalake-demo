output "glue_crawler_role_arn" {
  description = "ARN del rol IAM para Glue Crawler"
  value       = aws_iam_role.glue_crawler.arn
}

output "glue_job_role_arn" {
  description = "ARN del rol IAM para Glue Job"
  value       = aws_iam_role.glue_job.arn
}

output "lambda_sqs_trigger_role_arn" {
  description = "ARN del rol IAM para Lambda SQS trigger"
  value       = aws_iam_role.lambda_sqs_trigger.arn
}
