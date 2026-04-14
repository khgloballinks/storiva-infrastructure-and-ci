#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_FILE="$INFRA_DIR/backup-20260414-110305.json"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file not found: $BACKUP_FILE"
    echo "Please create a backup first using: cd terraform && terraform state pull > ../backup-$(date +%Y%m%d).json"
    exit 1
fi

DOMAIN_NAME="storivainc.com"

echo "=========================================="
echo "Storiva Terraform Migration Script"
echo "=========================================="
echo ""

echo "Step 1: Getting resource IDs from AWS..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text)
SG_SERVER=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=storiva-server-sg" --query 'SecurityGroups[0].GroupId' --output text)
SG_RDS=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=storiva-rds-sg" --query 'SecurityGroups[0].GroupId' --output text)

STAGING_INST=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=Storiva-Staging-Server" --query 'Reservations[0].Instances[0].InstanceId' --output text)
STAGING_ALLOC=$(aws ec2 describe-addresses --filters "Name=instance-id,Values=$STAGING_INST" --query 'Addresses[0].AllocationId' --output text)

PROD_INST=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=Storiva-Prod-Server" --query 'Reservations[0].Instances[0].InstanceId' --output text)
PROD_ALLOC=$(aws ec2 describe-addresses --filters "Name=instance-id,Values=$PROD_INST" --query 'Addresses[0].AllocationId' --output text)

ZONE_ID=$(aws route53 list-hosted-zones --query "HostedZones[?Name=='${DOMAIN_NAME}.'] | [0].Id" --output text)
echo "Resources identified:"
echo "  SG Server: $SG_SERVER"
echo "  SG RDS: $SG_RDS"
echo "  Staging Instance: $STAGING_INST"
echo "  Staging EIP: $STAGING_ALLOC"
echo "  Prod Instance: $PROD_INST"
echo "  Prod EIP: $PROD_ALLOC"
echo "  Zone ID: $ZONE_ID"
echo ""

echo "=========================================="
echo "Migrating STAGING environment"
echo "=========================================="
cd "$INFRA_DIR/environments/staging"

echo "Initializing staging..."
terraform init

echo "Restoring original state..."
cp "$BACKUP_FILE" terraform.tfstate.backup
terraform state push "$BACKUP_FILE" 2>/dev/null || true

echo "Moving resources to modules..."
terraform state mv 'aws_security_group.storiva_sg' 'module.security_group.aws_security_group.server'
terraform state mv 'aws_security_group.rds_sg' 'module.security_group.aws_security_group.rds'
terraform state mv 'aws_instance.staging_server' 'module.ec2.aws_instance.server'
terraform state mv 'aws_eip.staging_eip' 'module.ec2.aws_eip.server'
terraform state mv 'aws_route53_zone.main' 'module.route53.aws_route53_zone.main'
terraform state mv 'aws_route53_record.staging' 'module.route53.aws_route53_record.records["staging"]'

echo "Staging complete!"
echo ""

echo "=========================================="
echo "Migrating PRODUCTION environment"
echo "=========================================="
cd "$INFRA_DIR/environments/production"

echo "Initializing production..."
terraform init

echo "Restoring original state..."
terraform state push "$BACKUP_FILE" 2>/dev/null || true

echo "Moving resources to modules..."
terraform state mv 'aws_security_group.storiva_sg' 'module.security_group.aws_security_group.server'
terraform state mv 'aws_security_group.rds_sg' 'module.security_group.aws_security_group.rds'
terraform state mv 'aws_instance.prod_server' 'module.ec2.aws_instance.server'
terraform state mv 'aws_eip.prod_eip' 'module.ec2.aws_eip.server'
terraform state mv 'aws_db_subnet_group.storiva' 'module.rds.aws_db_subnet_group.main'
terraform state mv 'aws_db_instance.storiva_db' 'module.rds.aws_db_instance.main'
terraform state mv 'aws_route53_zone.main' 'module.route53.aws_route53_zone.main'
terraform state mv 'aws_route53_record.prod_root' 'module.route53.aws_route53_record.records["root"]'
terraform state mv 'aws_route53_record.prod_www' 'module.route53.aws_route53_record.records["www"]'
terraform state mv 'aws_route53_record.prod_api' 'module.route53.aws_route53_record.records["api"]'

echo "Production complete!"
echo ""

echo "=========================================="
echo "Verification: Running terraform plan"
echo "=========================================="
echo ""

echo "--- Staging Plan ---"
cd "$INFRA_DIR/environments/staging"
terraform plan -var-file="terraform.tfvars" 2>&1 | head -50
echo ""

echo "--- Production Plan ---"
cd "$INFRA_DIR/environments/production"
terraform plan -var-file="terraform.tfvars" 2>&1 | head -50
echo ""

echo "=========================================="
echo "Migration Complete!"
echo "=========================================="
