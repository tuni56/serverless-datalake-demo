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
          "glue:GetPartitions"
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
