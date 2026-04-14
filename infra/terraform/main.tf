terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "security_group" {
  source = "../modules/security-group"

  name_prefix   = "storiva"
  environment   = "shared"
  allowed_ips   = var.allowed_ips
  allowed_ports = [22, 80, 443, 8080, 8081]
}

module "ec2_staging" {
  source = "../modules/ec2"

  name_prefix       = "storiva-staging"
  environment       = "staging"
  instance_type     = var.staging_instance_type
  key_name          = var.key_name
  security_group_id = module.security_group.server_security_group_id
  volume_size       = var.staging_volume_size
  subnet_id         = "subnet-07225b4a1cddba961"
}

module "ec2_production" {
  source = "../modules/ec2"

  name_prefix       = "storiva-prod"
  environment       = "production"
  instance_type     = var.prod_instance_type
  key_name          = var.key_name
  security_group_id = module.security_group.server_security_group_id
  volume_size       = var.prod_volume_size
  subnet_id         = "subnet-07225b4a1cddba961"
}

module "rds" {
  source = "../modules/rds"

  name_prefix           = "storiva"
  environment           = "production"
  security_group_id     = module.security_group.rds_security_group_id
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  instance_class        = var.db_instance_class
  db_name               = var.db_name
  db_username           = var.db_username
  db_password           = var.db_password
}

module "route53" {
  source = "../modules/route53"

  name_prefix = "storiva"
  environment = "shared"
  domain_name = var.domain_name
  dns_records = {
    root = {
      name    = var.domain_name
      type    = "A"
      ttl     = 300
      records = [module.ec2_production.public_ip]
    }
    www = {
      name    = "www.${var.domain_name}"
      type    = "A"
      ttl     = 300
      records = [module.ec2_production.public_ip]
    }
    api = {
      name    = "api.${var.domain_name}"
      type    = "A"
      ttl     = 300
      records = [module.ec2_production.public_ip]
    }
    staging = {
      name    = "staging.${var.domain_name}"
      type    = "A"
      ttl     = 300
      records = [module.ec2_staging.public_ip]
    }
  }
}
