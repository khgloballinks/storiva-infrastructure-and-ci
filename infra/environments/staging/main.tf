terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
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

module "security_group" {
  source = "../../modules/security-group"

  name_prefix   = "storiva-staging"
  environment   = "staging"
  allowed_ips   = var.allowed_ips
  allowed_ports = [22, 80, 443, 8080, 8081]
}

module "ec2" {
  source = "../../modules/ec2"

  name_prefix       = "storiva-staging"
  environment       = "staging"
  instance_type     = var.instance_type
  key_name          = var.key_name
  security_group_id = module.security_group.server_security_group_id
  volume_size       = var.volume_size
}

module "route53" {
  source = "../../modules/route53"

  environment        = "staging"
  cloudflare_zone_id = var.cloudflare_zone_id
  dns_records = {
    staging = {
      name    = "staging.storivainc.com"
      type    = "A"
      value   = module.ec2.public_ip
      proxied = true
    }
  }
}
