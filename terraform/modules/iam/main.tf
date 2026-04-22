data "aws_caller_identity" "current" {}

# IAM Role para Glue Crawler
resource "aws_iam_role" "glue_crawler" {
  name = "${var.project_name}-glue-crawler-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# Policy para Glue Crawler
resource "aws_iam_role_policy" "glue_crawler" {
  name = "${var.project_name}-glue-crawler-policy-${var.environment}"
  role = aws_iam_role.glue_crawler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-raw-${data.aws_caller_identity.current.account_id}",
          "arn:aws:s3:::${var.project_name}-raw-${data.aws_caller_identity.current.account_id}/*",
          "arn:aws:s3:::${var.project_name}-curated-${data.aws_caller_identity.current.account_id}",
          "arn:aws:s3:::${var.project_name}-curated-${data.aws_caller_identity.current.account_id}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetTable",
          "glue:CreateTable",
          "glue:UpdateTable",
          "glue:CreatePartition",
          "glue:UpdatePartition"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:/aws-glue/*"
      }
    ]
  })
}

# IAM Role para Glue ETL Job
resource "aws_iam_role" "glue_job" {
  name = "${var.project_name}-glue-job-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# Policy para Glue ETL Job
resource "aws_iam_role_policy" "glue_job" {
  name = "${var.project_name}-glue-job-policy-${var.environment}"
  role = aws_iam_role.glue_job.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-raw-${data.aws_caller_identity.current.account_id}",
          "arn:aws:s3:::${var.project_name}-raw-${data.aws_caller_identity.current.account_id}/*",
          "arn:aws:s3:::${var.project_name}-curated-${data.aws_caller_identity.current.account_id}",
          "arn:aws:s3:::${var.project_name}-curated-${data.aws_caller_identity.current.account_id}/*",
          "arn:aws:s3:::${var.project_name}-scripts-${data.aws_caller_identity.current.account_id}",
          "arn:aws:s3:::${var.project_name}-scripts-${data.aws_caller_identity.current.account_id}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetTable",
          "glue:GetPartitions",
          "glue:GetConnection"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:/aws-glue/*"
      },
      {
        Sid    = "GlueVPCNetworking"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcAttribute",
          "ec2:DescribeVpcEndpoints",
          "ec2:DescribeRouteTables"
        ]
        Resource = "*"
      },
      {
        Sid    = "GlueVPCTags"
        Effect = "Allow"
        Action = [
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Resource = "arn:aws:ec2:*:*:network-interface/*"
        Condition = {
          "ForAllValues:StringEquals" = {
            "aws:TagKeys" = ["aws-glue-service-resource"]
          }
        }
      }
    ]
  })
}

# IAM Role para Lambda (trigger SQS → Glue)
resource "aws_iam_role" "lambda_sqs_trigger" {
  name = "${var.project_name}-lambda-sqs-trigger-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "lambda_sqs_trigger" {
  name = "${var.project_name}-lambda-sqs-trigger-policy-${var.environment}"
  role = aws_iam_role.lambda_sqs_trigger.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["glue:StartJobRun"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}
