locals {
  name = "enrollment"
  region = "us-east-1"
  tags = {
    App = "enrollment-api"
    Env = "dev"
  }
}

terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 3.0"
        }
    }
}

provider "aws" {
  region = "${local.region}"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "${local.name}-vpc"
  cidr = "10.99.0.0/18"

  azs              = ["${local.region}a", "${local.region}b", "${local.region}c"]
  public_subnets   = ["10.99.0.0/24", "10.99.1.0/24", "10.99.2.0/24"]
  private_subnets  = ["10.99.3.0/24", "10.99.4.0/24", "10.99.5.0/24"]
  database_subnets = ["10.99.7.0/24", "10.99.8.0/24", "10.99.9.0/24"]

  tags = local.tags
}

module "rds-aurora" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "6.2.0"

  master_password = var.db_master_password
  create_random_password = false

  name = "${local.name}-db"
  engine = "aurora-postgresql"
  engine_mode = "serverless"
  storage_encrypted = true

  vpc_id = module.vpc.vpc_id
  subnets = module.vpc.database_subnets
  create_security_group = true
  allowed_cidr_blocks = module.vpc.private_subnets_cidr_blocks

  monitoring_interval = 90

  apply_immediately = true
  skip_final_snapshot = true

  db_parameter_group_name = aws_db_parameter_group.db_params.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.cluster_params.id

  scaling_configuration = {
    auto_pause               = true
    min_capacity             = 2
    max_capacity             = 16
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }
  tags = local.tags
}

resource "aws_db_parameter_group" "db_params" {
  name        = "${local.name}-db-params"
  family      = "aurora-postgresql10"
  description = "${local.name} DB parameter group"
  tags        = local.tags
}

resource "aws_rds_cluster_parameter_group" "cluster_params" {
  name        = "${local.name}-db-params"
  family      = "aurora-postgresql10"
  description = "${local.name} RDS cluster parameter group"
  tags        = local.tags
}


