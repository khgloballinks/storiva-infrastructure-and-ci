# ──────────────────────────────────────
# AWS
# ──────────────────────────────────────
variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
}

variable "key_name" {
  description = "EC2 SSH key pair name (must exist in AWS)"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name for app storage"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "Your IP address for SSH access — format: x.x.x.x/32"
  type        = string

  validation {
    condition     = can(cidrhost(var.ssh_allowed_cidr, 0))
    error_message = "ssh_allowed_cidr must be a valid CIDR block e.g. 1.2.3.4/32"
  }
}

# ──────────────────────────────────────
# Database
# ──────────────────────────────────────
variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "storiva_staging"
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "storiva_staging_user"
}

variable "db_password" {
  description = "PostgreSQL master password — pass via TF_VAR_db_password"
  type        = string
  sensitive   = true
}



# ──────────────────────────────────────
# Cloudflare
# ──────────────────────────────────────
variable "cloudflare_api_token" {
  description = "Cloudflare API token — pass via TF_VAR_cloudflare_api_token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID — pass via TF_VAR_cloudflare_zone_id"
  type        = string
  sensitive   = true
}