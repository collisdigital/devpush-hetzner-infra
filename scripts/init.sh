#!/bin/bash
set -e

# This script configures dynamic environment variables and initializes Terraform.

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
