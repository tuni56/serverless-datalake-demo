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

module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags
}

module "s3" {
  source = "../../modules/s3"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags
}

module "glue" {
  source = "../../modules/glue"

  project_name           = var.project_name
  environment            = var.environment
  raw_bucket_name        = module.s3.raw_bucket_name
  curated_bucket_name    = module.s3.curated_bucket_name
  scripts_bucket_name    = module.s3.scripts_bucket_name
  glue_crawler_role_arn  = module.iam.glue_crawler_role_arn
  glue_job_role_arn      = module.iam.glue_job_role_arn
  tags                   = local.common_tags

  depends_on = [module.iam, module.s3]
}

module "athena" {
  source = "../../modules/athena"

  project_name                = var.project_name
  environment                 = var.environment
  athena_results_bucket_name  = module.s3.athena_results_bucket_name
  tags                        = local.common_tags

  depends_on = [module.s3]
}
