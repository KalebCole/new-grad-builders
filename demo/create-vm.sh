#!/usr/bin/env bash
# create-vm.sh — Create an Azure VM for OpenClaw
# Prerequisites: Azure CLI installed, logged in (az login), Visual Studio subscription active
# Usage: bash create-vm.sh

set -euo pipefail

RESOURCE_GROUP="personal-agents"
VM_NAME="openclaw-vm"
LOCATION="westus2"
IMAGE="Ubuntu2204"
SIZE="Standard_B2ms"
ADMIN_USER="azureuser"

echo "============================================"
echo "  New Grad Builders — Create Azure VM"
echo "============================================"
echo ""

# Check Azure CLI is installed
if ! command -v az &>/dev/null; then
  echo "ERROR: Azure CLI not found. Install it first:"
  echo "  https://learn.microsoft.com/en-us/cli/azure/install-azure-cli"
  exit 1
fi

# Check logged in
if ! az account show &>/dev/null 2>&1; then
  echo "ERROR: Not logged in to Azure. Run: az login"
  exit 1
fi

echo "Subscription: $(az account show --query name -o tsv)"
echo ""

# Create resource group
echo "[1/2] Creating resource group '${RESOURCE_GROUP}' in ${LOCATION}..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output none
echo "  ✓ Resource group ready"

# Create VM
echo "[2/2] Creating VM '${VM_NAME}' (${SIZE}, ${IMAGE})..."
echo "  This takes 1-2 minutes..."
VM_OUTPUT=$(az vm create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM_NAME" \
  --image "$IMAGE" \
  --size "$SIZE" \
  --admin-username "$ADMIN_USER" \
  --generate-ssh-keys \
  --output json)

PUBLIC_IP=$(echo "$VM_OUTPUT" | jq -r '.publicIpAddress')

echo "  ✓ VM created"
echo ""
echo "============================================"
echo "  ✅ VM Ready!"
echo "============================================"
echo ""
echo "  Public IP: ${PUBLIC_IP}"
echo ""
echo "  ⚠️  This VM is publicly accessible on port 22 (SSH)."
echo "  The bootstrap script will harden it with UFW + Tailscale."
echo ""
echo "NEXT STEPS:"
echo ""
echo "  1. SSH in:"
echo "     ssh ${ADMIN_USER}@${PUBLIC_IP}"
echo ""
echo "  2. Run the bootstrap script:"
echo "     curl -fsSL https://raw.githubusercontent.com/KalebCole/new-grad-builders/main/demo/setup-openclaw-vm.sh | sudo bash"
echo ""
