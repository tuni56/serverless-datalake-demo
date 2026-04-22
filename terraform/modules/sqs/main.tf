# DLQ para mensajes que no pudieron procesarse
resource "aws_sqs_queue" "glue_trigger_dlq" {
  name                      = "${var.project_name}-glue-trigger-dlq-${var.environment}"
  message_retention_seconds = 1209600 # 14 días
  tags                      = merge(var.tags, { Purpose = "dlq" })
}

# Cola principal: recibe eventos S3 y dispara el Glue Job
resource "aws_sqs_queue" "glue_trigger" {
  name                       = "${var.project_name}-glue-trigger-${var.environment}"
  visibility_timeout_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.glue_trigger_dlq.arn
    maxReceiveCount     = 3
  })

  tags = merge(var.tags, { Purpose = "glue-trigger" })
}

# Política para que S3 pueda publicar en la cola
resource "aws_sqs_queue_policy" "glue_trigger" {
  queue_url = aws_sqs_queue.glue_trigger.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.glue_trigger.arn
        Condition = {
          ArnLike = { "aws:SourceArn" = var.raw_bucket_arn }
        }
      }
    ]
  })
}
