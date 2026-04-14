terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "../../modules/vpc"
  env    = "prod"
}

module "ec2" {
  source    = "../../modules/ec2"
  env       = "prod"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnet_ids[0]
  key_name  = var.key_name
}

module "rds" {
  source             = "../../modules/rds"
  env                = "prod"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  allowed_sg_id      = module.ec2.rds_access_sg_id
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
}

module "s3" {
  source      = "../../modules/s3"
  env         = "prod"
  bucket_name = var.s3_bucket_name
}

terraform {
  required_providers {
    aws       = { source = "hashicorp/aws",       version = "~> 5.0" }
    cloudflare = { source = "cloudflare/cloudflare", version = "~> 4.0" }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# ... existing modules unchanged ...

module "cloudflare" {
  source      = "../../modules/cloudflare"
  env         = "prod"
  zone_id     = var.cloudflare_zone_id
  record_name = var.cloudflare_record_name   # e.g. "api" → api.yourdomain.com
  ip_address  = module.ec2.public_ip
  proxied     = true
}