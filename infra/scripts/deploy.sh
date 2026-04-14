#!/usr/bin/env bash
set -euo pipefail

show_usage() {
    cat << EOF
Usage: $(basename "$0") [plan|apply|destroy]

Actions:
  plan    - Preview changes (default)
  apply   - Apply changes
  destroy - Destroy all infrastructure (careful!)

Examples:
  $(basename "$0") plan
  $(basename "$0") apply
  $(basename "$0") destroy
EOF
}

ACTION="${1:-plan}"

if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
    echo "Error: Invalid action '$ACTION'"
    show_usage
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")/terraform"

echo "Working directory: $TERRAFORM_DIR"
echo "Action: $ACTION"
echo ""

cd "$TERRAFORM_DIR"

if [ ! -f "terraform.tfvars" ]; then
    echo "Error: terraform.tfvars not found"
    exit 1
fi

terraform init

echo "Validating configuration..."
terraform validate

echo ""

case "$ACTION" in
    plan)
        echo "Planning..."
        terraform plan
        ;;
    apply)
        echo "Applying..."
        terraform apply
        echo ""
        echo "Done! Outputs:"
        terraform output
        ;;
    destroy)
        echo "WARNING: This will destroy ALL infrastructure!"
        echo "WARNING: This includes EC2 instances, RDS, Elastic IPs and DNS records!"
        echo ""
        read -rp "Type 'yes' to confirm: " confirm
        if [ "$confirm" = "yes" ]; then
            terraform destroy
        else
            echo "Aborted."
        fi
        ;;
esac
