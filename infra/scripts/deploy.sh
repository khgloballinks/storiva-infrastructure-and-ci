#!/usr/bin/env bash
# ── deploy.sh ─────────────────────────────────────────────────────────────────
# Simple deploy script for the shared infrastructure.
# Usage:
#   ./infra/scripts/deploy.sh plan     → preview changes
#   ./infra/scripts/deploy.sh apply    → apply changes
#   ./infra/scripts/deploy.sh destroy  → destroy everything (careful!)

set -euo pipefail

TERRAFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../terraform" && pwd)"
ACTION="${1:-plan}"

echo "📁 Working directory: $TERRAFORM_DIR"
echo "🔧 Action: $ACTION"
echo "🌍 Workspace: $(terraform -chdir="$TERRAFORM_DIR" workspace show)"
echo ""

# ── Validate tfvars exists ────────────────────────────────────────────────────
if [ ! -f "$TERRAFORM_DIR/terraform.tfvars" ]; then
  echo "❌ terraform.tfvars not found in $TERRAFORM_DIR"
  exit 1
fi

cd "$TERRAFORM_DIR"

# ── Init ──────────────────────────────────────────────────────────────────────
terraform init -reconfigure

# ── Validate ──────────────────────────────────────────────────────────────────
echo "🔎 Validating configuration..."
terraform validate

echo ""

# ── Actions ───────────────────────────────────────────────────────────────────
case "$ACTION" in
  plan)
    echo "🔍 Planning..."
    terraform plan -var-file="terraform.tfvars"
    ;;
  apply)
    echo "🚀 Applying..."
    terraform apply -var-file="terraform.tfvars"
    echo ""
    echo "✅ Done! Outputs:"
    terraform output
    ;;
  destroy)
    echo "⚠️  WARNING: This will destroy ALL infrastructure!"
    echo "⚠️  This includes EC2 instances, RDS, Elastic IPs and DNS records!"
    echo ""
    read -rp "Type 'yes' to confirm: " confirm
    if [ "$confirm" = "yes" ]; then
      terraform destroy -var-file="terraform.tfvars"
    else
      echo "Aborted."
    fi
    ;;
  *)
    echo "❌ Unknown action: $ACTION"
    echo "Usage: $0 [plan|apply|destroy]"
    exit 1
    ;;
esac