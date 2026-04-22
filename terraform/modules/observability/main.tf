# SNS Topic para alertas
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts-${var.environment}"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Alarma: mensajes en DLQ
resource "aws_cloudwatch_metric_alarm" "dlq_not_empty" {
  alarm_name          = "${var.project_name}-dlq-not-empty-${var.environment}"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  dimensions          = { QueueName = var.dlq_name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  tags                = var.tags
}

# Alarma: Glue Job fallido
resource "aws_cloudwatch_metric_alarm" "glue_job_failed" {
  alarm_name          = "${var.project_name}-glue-job-failed-${var.environment}"
  namespace           = "Glue"
  metric_name         = "glue.driver.aggregate.numFailedTasks"
  dimensions          = { JobName = var.glue_job_name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  tags                = var.tags
}

# Dashboard de pipeline
resource "aws_cloudwatch_dashboard" "pipeline" {
  dashboard_name = "${var.project_name}-pipeline-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title  = "DLQ - Mensajes visibles"
          region = "us-east-2"
          metrics = [["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", var.dlq_name]]
          period = 300
          stat   = "Sum"
        }
      },
      {
        type = "metric"
        properties = {
          title  = "Glue Job - Tareas fallidas"
          region = "us-east-2"
          metrics = [["Glue", "glue.driver.aggregate.numFailedTasks", "JobName", var.glue_job_name]]
          period = 300
          stat   = "Sum"
        }
      },
      {
        type = "metric"
        properties = {
          title  = "SQS - Mensajes enviados"
          region = "us-east-2"
          metrics = [["AWS/SQS", "NumberOfMessagesSent", "QueueName", "${var.project_name}-glue-trigger-${var.environment}"]]
          period = 300
          stat   = "Sum"
        }
      }
    ]
  })
}
