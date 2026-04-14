# Cloudflare DNS Integration Notes

## Overview

Migrated DNS from AWS Route53 to Cloudflare for the `storivainc.com` domain across both production and staging environments.

## What Was Done

### 1. Added Cloudflare Provider

**Files Modified:**
- `environments/production/main.tf`
- `environments/staging/main.tf`

**Changes:**
```hcl
terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
```

### 2. Added Required Variables

**Files Modified:**
- `environments/production/variables.tf`
- `environments/staging/variables.tf`

**New Variables:**
```hcl
variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID"
  type        = string
}
```

### 3. Updated Route53 Module

**Files Modified:**
- `modules/route53/main.tf`
- `modules/route53/variables.tf`
- `modules/route53/outputs.tf`

**Changes:**
- Replaced `aws_route53_zone` and `aws_route53_record` with `cloudflare_record`
- Simplified record structure (removed TTL, added `proxied` boolean)
- Updated to use `cloudflare_zone_id` instead of creating AWS zone

### 4. Updated Environment Configs

**Production (`environments/production/main.tf`):**
- 3 DNS records: `storivainc.com`, `www.storivainc.com`, `api.storivainc.com`
- All proxied through Cloudflare

**Staging (`environments/staging/main.tf`):**
- 1 DNS record: `staging.storivainc.com`
- Proxied through Cloudflare

### 5. Added tfvars Values

**Files Modified:**
- `environments/production/terraform.tfvars`
- `environments/staging/terraform.tfvars`

**Placeholders Added:**
```hcl
cloudflare_api_token = "your-cloudflare-api-token"
cloudflare_zone_id   = "your-cloudflare-zone-id"
```

## Remaining Setup

### Get Cloudflare Credentials

1. **API Token:**
   - Go to Cloudflare Dashboard
   - Profile → API Tokens
   - Create Custom Token or use "Edit zone DNS" template
   - Grant permissions: `Zone:DNS:Read`, `Zone:DNS:Edit`

2. **Zone ID:**
   - Go to Cloudflare Dashboard
   - Select `storivainc.com` domain
   - Find Zone ID in the right sidebar (Overview page)

### Update tfvars Files

Replace placeholder values in both `terraform.tfvars` files:

```hcl
cloudflare_api_token = "your-actual-token"
cloudflare_zone_id   = "your-actual-zone-id"
```

## How to Deploy

```bash
# Production
cd environments/production
terraform init
terraform plan
terraform apply

# Staging
cd environments/staging
terraform init
terraform plan
terraform apply
```

## DNS Record Mapping

| Environment | Record | Type | Proxied |
|-------------|--------|------|---------|
| Production | storivainc.com | A | Yes |
| Production | www.storivainc.com | A | Yes |
| Production | api.storivainc.com | A | Yes |
| Staging | staging.storivainc.com | A | Yes |

## Notes

- Cloudflare handles SSL automatically (Universal SSL)
- No TTL configuration needed (Cloudflare uses 300s)
- Records point to EC2 public IPs
- All traffic proxied through Cloudflare for DDoS protection and caching