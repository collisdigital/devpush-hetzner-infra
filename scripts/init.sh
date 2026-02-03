#!/bin/bash
set -e

# This script configures dynamic environment variables and initializes Terraform.

# 1. Configure Dynamic Variables (Optional overrides)
# It checks if specific "VAR_*" variables are set (from GitHub Actions vars or local env)
# and exports them as standard "TF_VAR_*" variables if they are.

# Check and export hcloud_server_type
if [ -n "$VAR_SERVER_TYPE" ]; then
    echo "Setting TF_VAR_hcloud_server_type..."
    export TF_VAR_hcloud_server_type="$VAR_SERVER_TYPE"
    # For GitHub Actions, we also write to GITHUB_ENV
    if [ -n "$GITHUB_ENV" ]; then
        echo "TF_VAR_hcloud_server_type=$VAR_SERVER_TYPE" >> $GITHUB_ENV
    fi
fi

# Check and export hcloud_image
if [ -n "$VAR_IMAGE" ]; then
    echo "Setting TF_VAR_hcloud_image..."
    export TF_VAR_hcloud_image="$VAR_IMAGE"
    if [ -n "$GITHUB_ENV" ]; then
        echo "TF_VAR_hcloud_image=$VAR_IMAGE" >> $GITHUB_ENV
    fi
fi

# Check and export devpush_service_username
if [ -n "$VAR_SERVICE_USER" ]; then
    echo "Setting TF_VAR_devpush_service_username..."
    export TF_VAR_devpush_service_username="$VAR_SERVICE_USER"
    if [ -n "$GITHUB_ENV" ]; then
        echo "TF_VAR_devpush_service_username=$VAR_SERVICE_USER" >> $GITHUB_ENV
    fi
fi

# Check and export devpush_volume_size
if [ -n "$VAR_VOLUME_SIZE" ]; then
    echo "Setting TF_VAR_devpush_volume_size..."
    export TF_VAR_devpush_volume_size="$VAR_VOLUME_SIZE"
    if [ -n "$GITHUB_ENV" ]; then
        echo "TF_VAR_devpush_volume_size=$VAR_VOLUME_SIZE" >> $GITHUB_ENV
    fi
fi

echo "Dynamic variables configured."

# 2. Run Terraform Init
echo "Running Terraform Init..."

# Determine arguments based on environment variables
INIT_ARGS=""

if [ -n "$TF_BACKEND_BUCKET" ]; then
  INIT_ARGS="$INIT_ARGS -backend-config=\"bucket=${TF_BACKEND_BUCKET}\""
fi

if [ -n "$TF_BACKEND_KEY" ]; then
  INIT_ARGS="$INIT_ARGS -backend-config=\"key=${TF_BACKEND_KEY}\""
fi

if [ -n "$TF_BACKEND_REGION" ]; then
  INIT_ARGS="$INIT_ARGS -backend-config=\"region=${TF_BACKEND_REGION}\""
fi

if [ -n "$TF_BACKEND_ENDPOINT" ]; then
  INIT_ARGS="$INIT_ARGS -backend-config=\"endpoint=${TF_BACKEND_ENDPOINT}\""
fi

# If using S3 backend with credentials provided via env vars, we might not need to pass them explicitly
# if Terraform picks up standard AWS_* env vars, but providing them via config is safer for non-standard providers.
# However, `backend "s3"` usually respects AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY automatically.
# The previous workflow didn't pass access/secret key via -backend-config, it relied on env vars.
# Wait, checking memory/previous files...
# The previous README said: -backend-config="access_key=$AWS_ACCESS_KEY_ID"
# But the previous workflow file (read earlier) said:
# terraform init -backend-config="bucket=${TF_BACKEND_BUCKET}" ... (no access key)
# It relied on `AWS_ACCESS_KEY_ID` being in the env.
# So I will NOT add access keys to the command line arguments to avoid leaking them in logs if set -x is on (though it's off).

# Construct the command
CMD="terraform init $INIT_ARGS"

# Execute
echo "Executing: terraform init (with backend config hidden)"
eval "$CMD"
