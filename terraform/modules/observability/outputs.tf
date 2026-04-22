output "sns_topic_arn" {
  description = "ARN del SNS topic de alertas"
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_name" {
  description = "Nombre del CloudWatch Dashboard"
  value       = aws_cloudwatch_dashboard.pipeline.dashboard_name
}
