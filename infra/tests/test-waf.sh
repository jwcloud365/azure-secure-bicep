#!/bin/bash

# Test script for WAF (Web Application Firewall) components
# This script validates that the WAF resources have been deployed correctly

# Exit on error
set -e

# Configuration
SUBSCRIPTION_ID="your-subscription-id"
RESOURCE_GROUP="contoso-dev-rg"
WAF_NAME="contoso-dev-waf"
WAF_PUBLIC_IP_NAME="contoso-dev-waf-pip"

# Login and set subscription
echo "Logging into Azure..."
az account set --subscription $SUBSCRIPTION_ID

echo "Testing WAF components..."

# Test WAF Public IP existence
echo "Testing WAF Public IP existence..."
WAF_PUBLIC_IP=$(az network public-ip show --resource-group $RESOURCE_GROUP --name $WAF_PUBLIC_IP_NAME)
if [ -z "$WAF_PUBLIC_IP" ]; then
  echo "ERROR: WAF Public IP not found!"
  exit 1
fi
echo "WAF Public IP exists."

# Verify Public IP allocation method
ALLOCATION_METHOD=$(echo $WAF_PUBLIC_IP | jq -r '.publicIPAllocationMethod')
if [ "$ALLOCATION_METHOD" != "Static" ]; then
  echo "ERROR: WAF Public IP is not using static allocation!"
  exit 1
fi
echo "WAF Public IP is correctly configured with static allocation."

# Verify Public IP SKU
SKU=$(echo $WAF_PUBLIC_IP | jq -r '.sku.name')
if [ "$SKU" != "Standard" ]; then
  echo "ERROR: WAF Public IP is not using Standard SKU!"
  exit 1
fi
echo "WAF Public IP has the correct SKU."

# Test WAF (Application Gateway) existence
echo "Testing WAF existence..."
WAF=$(az network application-gateway show --resource-group $RESOURCE_GROUP --name $WAF_NAME)
if [ -z "$WAF" ]; then
  echo "ERROR: WAF not found!"
  exit 1
fi
echo "WAF exists."

# Verify WAF SKU
WAF_SKU=$(echo $WAF | jq -r '.sku.tier')
if [ "$WAF_SKU" != "WAF_v2" ]; then
  echo "ERROR: WAF is not using WAF_v2 SKU!"
  exit 1
fi
echo "WAF has the correct SKU."

# Verify WAF is enabled
WAF_ENABLED=$(echo $WAF | jq -r '.webApplicationFirewallConfiguration.enabled')
if [ "$WAF_ENABLED" != "true" ]; then
  echo "ERROR: WAF is not enabled!"
  exit 1
fi
echo "WAF is correctly enabled."

# Verify WAF mode
WAF_MODE=$(echo $WAF | jq -r '.webApplicationFirewallConfiguration.firewallMode')
if [ "$WAF_MODE" != "Prevention" ]; then
  echo "ERROR: WAF is not in Prevention mode!"
  exit 1
fi
echo "WAF is correctly set to Prevention mode."

# Verify WAF rule set
WAF_RULE_SET=$(echo $WAF | jq -r '.webApplicationFirewallConfiguration.ruleSetType')
if [ "$WAF_RULE_SET" != "OWASP" ]; then
  echo "ERROR: WAF is not using OWASP rule set!"
  exit 1
fi
echo "WAF is correctly using OWASP rule set."

echo "All WAF components have been successfully deployed and validated!"
