#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# deploy-azure.sh — Deploy Azure Cosmos DB for MongoDB (vCore) cluster
#
# Creates a resource group, a MongoDB vCore cluster (free tier by default),
# configures a firewall rule for your current IP, and outputs the connection
# string ready for .env.
#
# Usage:
#   bash scripts/deploy-azure.sh
#   bash scripts/deploy-azure.sh --cluster-name my-memory --location eastus
#
# Prerequisites:
#   - Azure CLI (az) installed and logged in: az login
#   - Sufficient permissions to create resources in the target subscription
###############################################################################

# Defaults (override via environment variables or flags)
RESOURCE_GROUP="${RESOURCE_GROUP:-personal-memory-rg}"
CLUSTER_NAME="${CLUSTER_NAME:-personal-memory-docdb}"
LOCATION="${LOCATION:-eastus}"
ADMIN_USER="${ADMIN_USER:-memadmin}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-}"
TIER="${TIER:-Free}"
DB_NAME="${DB_NAME:-personal_memory}"

# Parse optional flags
while [[ $# -gt 0 ]]; do
  case $1 in
    --resource-group) RESOURCE_GROUP="$2"; shift 2 ;;
    --cluster-name)   CLUSTER_NAME="$2"; shift 2 ;;
    --location)       LOCATION="$2"; shift 2 ;;
    --admin-user)     ADMIN_USER="$2"; shift 2 ;;
    --admin-password) ADMIN_PASSWORD="$2"; shift 2 ;;
    --tier)           TIER="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Generate a password if not provided
if [[ -z "$ADMIN_PASSWORD" ]]; then
  ADMIN_PASSWORD="P$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 16)!"
  echo "🔑 Generated admin password (save this!): $ADMIN_PASSWORD"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Azure Cosmos DB for MongoDB (vCore) — Deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Resource Group : $RESOURCE_GROUP"
echo "  Cluster Name   : $CLUSTER_NAME"
echo "  Location       : $LOCATION"
echo "  Admin User     : $ADMIN_USER"
echo "  Tier           : $TIER"
echo "  Database       : $DB_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Step 1: Ensure az is logged in
echo ""
echo "⏳ Checking Azure CLI login..."
if ! az account show &>/dev/null; then
  echo "❌ Not logged in. Run 'az login' first."
  exit 1
fi
SUBSCRIPTION=$(az account show --query name -o tsv)
echo "✅ Logged in to subscription: $SUBSCRIPTION"

# Step 2: Create resource group
echo ""
echo "⏳ Creating resource group '$RESOURCE_GROUP' in '$LOCATION'..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output none
echo "✅ Resource group ready"

# Step 3: Create the MongoDB vCore cluster
echo ""
echo "⏳ Creating MongoDB vCore cluster '$CLUSTER_NAME' (tier: $TIER)..."
echo "   This may take 5-10 minutes..."
az cosmosdb mongocluster create \
  --cluster-name "$CLUSTER_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --administrator-login "$ADMIN_USER" \
  --administrator-login-password "$ADMIN_PASSWORD" \
  --server-version "7.0" \
  --shard-node-tier "$TIER" \
  --shard-node-disk-size-gb 32 \
  --shard-node-count 1 \
  --output none
echo "✅ Cluster created"

# Step 4: Add firewall rule for current IP
echo ""
echo "⏳ Detecting your public IP..."
MY_IP=$(curl -s https://ifconfig.me || curl -s https://api.ipify.org || echo "")
if [[ -z "$MY_IP" ]]; then
  echo "⚠️  Could not detect public IP. Add a firewall rule manually:"
  echo "   az cosmosdb mongocluster firewall rule create \\"
  echo "     --cluster-name $CLUSTER_NAME --resource-group $RESOURCE_GROUP \\"
  echo "     --rule-name allowMyIP --start-ip-address <YOUR_IP> --end-ip-address <YOUR_IP>"
else
  echo "   Your IP: $MY_IP"
  az cosmosdb mongocluster firewall rule create \
    --cluster-name "$CLUSTER_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --rule-name "dev-machine" \
    --start-ip-address "$MY_IP" \
    --end-ip-address "$MY_IP" \
    --output none
  echo "✅ Firewall rule added for $MY_IP"
fi

# Step 5: Get the cluster endpoint
echo ""
echo "⏳ Retrieving cluster endpoint..."
FQDN=$(az cosmosdb mongocluster show \
  --cluster-name "$CLUSTER_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "connectionString" -o tsv 2>/dev/null || \
  az cosmosdb mongocluster show \
    --cluster-name "$CLUSTER_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.connectionString" -o tsv 2>/dev/null || echo "")

# If connectionString is not available, build it from FQDN
if [[ -z "$FQDN" || "$FQDN" == "None" ]]; then
  FQDN=$(az cosmosdb mongocluster show \
    --cluster-name "$CLUSTER_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.serverVersion" -o tsv 2>/dev/null || echo "")
  # Fallback: construct from cluster name
  ENDPOINT="${CLUSTER_NAME}.mongocluster.cosmos.azure.com"
  CONNECTION_STRING="mongodb+srv://${ADMIN_USER}:${ADMIN_PASSWORD}@${ENDPOINT}/${DB_NAME}?tls=true&authMechanism=SCRAM-SHA-256&retrywrites=false&maxIdleTimeMS=120000"
else
  # Use the returned connection string, inject credentials and DB
  CONNECTION_STRING=$(echo "$FQDN" | sed "s|mongodb+srv://|mongodb+srv://${ADMIN_USER}:${ADMIN_PASSWORD}@|" | sed "s|/?|/${DB_NAME}?|")
fi

# Step 6: Output results
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Deployment Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Add this to your mcp-server/.env file:"
echo ""
echo "  DOCUMENTDB_URI=$CONNECTION_STRING"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Admin User     : $ADMIN_USER"
echo "  Admin Password : $ADMIN_PASSWORD"
echo "  Cluster        : $CLUSTER_NAME"
echo "  Resource Group : $RESOURCE_GROUP"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  To tear down all resources:"
echo "    az group delete --name $RESOURCE_GROUP --yes --no-wait"
echo ""
