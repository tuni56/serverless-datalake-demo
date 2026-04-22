data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/../../../glue-jobs/sqs_glue_trigger.py"
  output_path = "${path.module}/sqs_glue_trigger.zip"
}

resource "aws_lambda_function" "sqs_glue_trigger" {
  function_name    = "${var.project_name}-sqs-glue-trigger-${var.environment}"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  handler          = "sqs_glue_trigger.handler"
  runtime          = "python3.11"
  role             = var.lambda_role_arn
  timeout          = 60

  environment {
    variables = {
      GLUE_JOB_NAME = var.glue_job_name
    }
  }

  tags = var.tags
}

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.sqs_glue_trigger.arn
  batch_size       = 1
}
