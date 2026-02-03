#!/bin/bash
set -e

# Check for required environment variables
REQUIRED_VARS=(
  "AWS_ACCESS_KEY_ID"
  "AWS_SECRET_ACCESS_KEY"
  "TF_VAR_hcloud_token"
  "TF_VAR_cloudflare_api_token"
  "TF_VAR_cloudflare_account_id"
  "TF_VAR_cloudflare_access_email"
  "TF_VAR_hcloud_ssh_key_name"
  "TF_VAR_domain_name"
  "TF_VAR_devpush_cloudflare_api_token"
  "TF_VAR_devpush_github_app_id"
  "TF_VAR_devpush_github_app_name"
  "TF_VAR_devpush_github_app_private_key"
  "TF_VAR_devpush_github_app_webhook_secret"
  "TF_VAR_devpush_github_app_client_id"
  "TF_VAR_devpush_github_app_client_secret"
  "TF_VAR_devpush_resend_api_key"
)

MISSING_VARS=()
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    MISSING_VARS+=("$var")
  fi
done

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
  echo "Error: The following required environment variables are missing:"
  for var in "${MISSING_VARS[@]}"; do
    echo "  - $var"
  done
  echo ""
  echo "Please set them before running this script."
  echo "You can use a .tfvars file locally, but these checks expect environment variables."
  exit 1
fi

echo "All required environment variables are set."
