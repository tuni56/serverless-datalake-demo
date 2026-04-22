terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  tags         = local.common_tags
}

module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags
}

module "s3" {
  source = "../../modules/s3"

  project_name           = var.project_name
  environment            = var.environment
  glue_trigger_queue_arn = module.sqs.glue_trigger_queue_arn
  tags                   = local.common_tags

  depends_on = [module.sqs]
}

module "sqs" {
  source = "../../modules/sqs"

  project_name   = var.project_name
  environment    = var.environment
  raw_bucket_arn = "arn:aws:s3:::${var.project_name}-raw-*"
  tags           = local.common_tags
}

module "glue" {
  source = "../../modules/glue"

  project_name          = var.project_name
  environment           = var.environment
  raw_bucket_name       = module.s3.raw_bucket_name
  curated_bucket_name   = module.s3.curated_bucket_name
  scripts_bucket_name   = module.s3.scripts_bucket_name
  glue_crawler_role_arn = module.iam.glue_crawler_role_arn
  glue_job_role_arn     = module.iam.glue_job_role_arn
  subnet_id             = module.vpc.private_subnet_ids[0]
  subnet_az             = module.vpc.private_subnet_azs[0]
  security_group_id     = module.vpc.vpc_endpoints_security_group_id
  tags                  = local.common_tags

  depends_on = [module.iam, module.s3, module.vpc]
}

module "lambda" {
  source = "../../modules/lambda"

  project_name    = var.project_name
  environment     = var.environment
  glue_job_name   = module.glue.job_name
  sqs_queue_arn   = module.sqs.glue_trigger_queue_arn
  lambda_role_arn = module.iam.lambda_sqs_trigger_role_arn
  tags            = local.common_tags

  depends_on = [module.glue, module.sqs, module.iam]
}

module "athena" {
  source = "../../modules/athena"

  project_name               = var.project_name
  environment                = var.environment
  athena_results_bucket_name = module.s3.athena_results_bucket_name
  tags                       = local.common_tags

  depends_on = [module.s3]
}

module "observability" {
  source = "../../modules/observability"

  project_name  = var.project_name
  environment   = var.environment
  glue_job_name = module.glue.job_name
  dlq_name      = module.sqs.dlq_name
  alert_email   = var.alert_email
  tags          = local.common_tags

  depends_on = [module.glue, module.sqs]
}
