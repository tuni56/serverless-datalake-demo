output "glue_trigger_queue_arn" {
  description = "ARN de la cola SQS principal"
  value       = aws_sqs_queue.glue_trigger.arn
}

output "glue_trigger_queue_url" {
  description = "URL de la cola SQS principal"
  value       = aws_sqs_queue.glue_trigger.id
}

output "dlq_arn" {
  description = "ARN de la Dead Letter Queue"
  value       = aws_sqs_queue.glue_trigger_dlq.arn
}

output "dlq_name" {
  description = "Nombre de la Dead Letter Queue"
  value       = aws_sqs_queue.glue_trigger_dlq.name
}
