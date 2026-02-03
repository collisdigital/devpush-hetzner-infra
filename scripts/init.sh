#!/bin/bash
set -e

# This script configures dynamic environment variables and initializes Terraform.

# 1. Configure Dynamic Variables (Optional overrides)
# It checks if specific "VAR_*" variables are set (from GitHub Actions vars or local env)
# and exports them as standard "TF_VAR_*" variables if they are.

# List of optional variables to check and map
# Format: VAR_NAME (the script expects this variable to be set)
# It maps VAR_NAME -> TF_VAR_name (lowercase, stripped of VAR_)
OPTIONAL_VARS=(
  "VAR_HCLOUD_SERVER_TYPE"
  "VAR_HCLOUD_IMAGE"
  "VAR_HCLOUD_DEVPUSH_SERVICE_USERNAME"
  "VAR_HCLOUD_SSH_LOGIN_USERNAME"
  "VAR_HCLOUD_LOCATION"
  "VAR_HCLOUD_VOLUME_SIZE_GB"
)

for var in "${OPTIONAL_VARS[@]}"; do
  # Indirect expansion to check if variable is set and not empty
  if [ -n "${!var}" ]; then
    # Construct TF_VAR name: remove VAR_ prefix and convert to lowercase
    # e.g. VAR_HCLOUD_SERVER_TYPE -> TF_VAR_hcloud_server_type
    suffix="${var#VAR_}"
    tf_var_name="TF_VAR_$(echo "$suffix" | tr '[:upper:]' '[:lower:]')"

    echo "Setting $tf_var_name..."
    export "$tf_var_name"="${!var}"

    # For GitHub Actions, we also write to GITHUB_ENV to persist for subsequent steps
    if [ -n "$GITHUB_ENV" ]; then
        echo "$tf_var_name=${!var}" >> $GITHUB_ENV
    fi
  fi
done

echo "Dynamic variables configured."

# 2. Run Terraform Init
echo "Running Terraform Init..."

# Define backend config mapping: EnvVar -> BackendConfigKey
# Using array of "EnvVar:ConfigKey" strings
BACKEND_MAPPINGS=(
  "TF_BACKEND_BUCKET:bucket"
  "TF_BACKEND_KEY:key"
  "TF_BACKEND_REGION:region"
  "TF_BACKEND_ENDPOINT:endpoint"
)

INIT_ARGS=""

for mapping in "${BACKEND_MAPPINGS[@]}"; do
  env_var="${mapping%%:*}"
  config_key="${mapping#*:}"

  if [ -n "${!env_var}" ]; then
    INIT_ARGS="$INIT_ARGS -backend-config=\"$config_key=${!env_var}\""
  fi
done

# Construct the command
CMD="terraform init $INIT_ARGS"

# Execute
echo "Executing: terraform init (with backend config hidden)"
eval "$CMD"
