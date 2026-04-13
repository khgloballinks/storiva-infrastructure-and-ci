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
echo ""

cd "$TERRAFORM_DIR"

# Init if .terraform folder doesn't exist
if [ ! -d ".terraform" ]; then
  echo "🔄 Running terraform init..."
  terraform init
fi

case "$ACTION" in
  plan)
    echo "🔍 Planning..."
    terraform plan -var-file="terraform.tfvars"
    ;;
  apply)
    echo "🚀 Applying..."
    terraform apply -var-file="terraform.tfvars" -auto-approve
    echo ""
    echo "✅ Done! Outputs:"
    terraform output
    ;;
  destroy)
    echo "⚠️  WARNING: This will destroy ALL infrastructure!"
    read -rp "Type 'yes' to confirm: " confirm
    if [ "$confirm" = "yes" ]; then
      terraform destroy -var-file="terraform.tfvars" -auto-approve
    else
      echo "Aborted."
    fi
    ;;
  *)
    echo "Unknown action: $ACTION"
    echo "Usage: $0 [plan|apply|destroy]"
    exit 1
    ;;
esac
