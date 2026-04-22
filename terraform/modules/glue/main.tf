# Glue Database
resource "aws_glue_catalog_database" "ecommerce" {
  name        = "${var.project_name}_${var.environment}"
  description = "Database para datos de e-commerce"
}

# Glue Crawler para datos RAW
resource "aws_glue_crawler" "raw" {
  name          = "${var.project_name}-raw-crawler-${var.environment}"
  role          = var.glue_crawler_role_arn
  database_name = aws_glue_catalog_database.ecommerce.name

  s3_target {
    path = "s3://${var.raw_bucket_name}/orders/"
  }

  s3_target {
    path = "s3://${var.raw_bucket_name}/customers/"
  }

  s3_target {
    path = "s3://${var.raw_bucket_name}/products/"
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
    }
  })

  tags = var.tags
}

# Glue Crawler para datos CURATED
resource "aws_glue_crawler" "curated" {
  name          = "${var.project_name}-curated-crawler-${var.environment}"
  role          = var.glue_crawler_role_arn
  database_name = aws_glue_catalog_database.ecommerce.name

  s3_target {
    path = "s3://${var.curated_bucket_name}/orders/"
  }

  s3_target {
    path = "s3://${var.curated_bucket_name}/customers/"
  }

  s3_target {
    path = "s3://${var.curated_bucket_name}/products/"
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
    }
  })

  tags = var.tags
}

# Glue Connection para VPC
resource "aws_glue_connection" "vpc" {
  name            = "${var.project_name}-vpc-connection-${var.environment}"
  connection_type = "NETWORK"

  physical_connection_requirements {
    subnet_id              = var.subnet_id
    availability_zone      = var.subnet_az
    security_group_id_list = [var.security_group_id]
  }

  tags = var.tags
}

# Glue ETL Job
resource "aws_glue_job" "transform" {
  name        = "${var.project_name}-transform-${var.environment}"
  role_arn    = var.glue_job_role_arn
  connections = [aws_glue_connection.vpc.name]

  command {
    name            = "pythonshell"
    script_location = "s3://${var.scripts_bucket_name}/transform_raw_to_curated.py"
    python_version  = "3.9"
  }

  default_arguments = {
    "--job-language"        = "python"
    "--job-bookmark-option" = "job-bookmark-enable"
    "--RAW_BUCKET"          = var.raw_bucket_name
    "--CURATED_BUCKET"      = var.curated_bucket_name
    "--DATABASE_NAME"       = aws_glue_catalog_database.ecommerce.name
  }

  max_capacity = 1
  timeout      = 60

  tags = var.tags
}
