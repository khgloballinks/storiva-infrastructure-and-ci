terraform {

  required_version = ">= 1.5.0" # ✅ Prevents old Terraform versions


  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# ──────────────────────────────────────
# Network
# ──────────────────────────────────────
module "vpc" {
  source = "../../modules/vpc"
  env    = "prod"
  vpc_cidr  = "10.0.0.0/16"
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
}

# ──────────────────────────────────────
# Compute
# ──────────────────────────────────────
module "ec2" {
  source           = "../../modules/ec2"
  env              = "prod"
  vpc_id           = module.vpc.vpc_id
  subnet_id        = module.vpc.public_subnet_ids[0]
  key_name         = var.key_name
  ssh_allowed_cidr = var.ssh_allowed_cidr
  internet_gateway_id = module.vpc.internet_gateway_id
}

# ──────────────────────────────────────
# Database
# ──────────────────────────────────────
module "rds" {
  source             = "../../modules/rds"
  env                = "prod"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  allowed_sg_ids     = [module.ec2.security_group_id]
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password

  deletion_protection = true
  skip_final_snapshot = false
  multi_az            = false
  instance_class      = "db.t3.micro"
}

# ──────────────────────────────────────
# Storage
# ──────────────────────────────────────
module "s3" {
  source      = "../../modules/s3"
  env         = "prod"
  bucket_name = var.s3_bucket_name
}

# ──────────────────────────────────────
# DNS
# ──────────────────────────────────────
module "cloudflare" {
  source  = "../../modules/cloudflare"
  env     = "prod"
  zone_id = var.cloudflare_zone_id

  records = {
    api_prod = {
      name    = "api"
      value   = module.ec2.public_ip
      type    = "A"
      ttl     = 1
      proxied = true
    }
  }
}
