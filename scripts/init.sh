#!/bin/bash
set -e

# This script configures dynamic environment variables for Terraform
# It checks if specific "VAR_*" variables are set (from GitHub Actions vars or local env)
# and exports them as standard "TF_VAR_*" variables if they are.
# This preserves Terraform defaults when the optional variables are not set.

# Check and export hcloud_server_type
if [ -n "$VAR_SERVER_TYPE" ]; then
    echo "Setting TF_VAR_hcloud_server_type..."
    echo "TF_VAR_hcloud_server_type=$VAR_SERVER_TYPE" >> $GITHUB_ENV 2>/dev/null || export TF_VAR_hcloud_server_type="$VAR_SERVER_TYPE"
fi

# Check and export hcloud_image
if [ -n "$VAR_IMAGE" ]; then
    echo "Setting TF_VAR_hcloud_image..."
    echo "TF_VAR_hcloud_image=$VAR_IMAGE" >> $GITHUB_ENV 2>/dev/null || export TF_VAR_hcloud_image="$VAR_IMAGE"
fi

# Check and export devpush_service_username
if [ -n "$VAR_SERVICE_USER" ]; then
    echo "Setting TF_VAR_devpush_service_username..."
    echo "TF_VAR_devpush_service_username=$VAR_SERVICE_USER" >> $GITHUB_ENV 2>/dev/null || export TF_VAR_devpush_service_username="$VAR_SERVICE_USER"
fi

# Check and export devpush_volume_size
if [ -n "$VAR_VOLUME_SIZE" ]; then
    echo "Setting TF_VAR_devpush_volume_size..."
    echo "TF_VAR_devpush_volume_size=$VAR_VOLUME_SIZE" >> $GITHUB_ENV 2>/dev/null || export TF_VAR_devpush_volume_size="$VAR_VOLUME_SIZE"
fi

echo "Dynamic variables configured."
