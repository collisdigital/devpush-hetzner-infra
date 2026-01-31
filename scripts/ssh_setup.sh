#!/bin/bash
set -e

# Configuration (defaults)
KEY_FILE="$HOME/.ssh/devpush_hcloud_key"
HOST_ALIAS="devpush"
HOSTNAME="devpush-direct.collis.digital"
USER="admin"

# Check if the secret is available
if [ -z "$HCLOUD_SSH_KEY" ]; then
    echo "Error: HCLOUD_SSH_KEY environment variable is not set."
    echo "Please add 'HCLOUD_SSH_KEY' as a Secret in your Codespace or environment."
    echo "Value should be the private key content (PEM format)."
    exit 1
fi

# Ensure .ssh directory exists
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Save the private key to a file
echo "Saving SSH key to $KEY_FILE..."
echo "$HCLOUD_SSH_KEY" > "$KEY_FILE"
chmod 600 "$KEY_FILE"

# Configure SSH Config
CONFIG_FILE="$HOME/.ssh/config"
if [ ! -f "$CONFIG_FILE" ]; then
    touch "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
fi

# Check if the host alias already exists
if grep -q "^Host $HOST_ALIAS$" "$CONFIG_FILE"; then
    echo "Entry for 'Host $HOST_ALIAS' already exists in $CONFIG_FILE."
    echo "Please manually ensure it points to:"
    echo "  HostName $HOSTNAME"
    echo "  User $USER"
    echo "  IdentityFile $KEY_FILE"
else
    echo "Adding entry to $CONFIG_FILE..."
    # Add a newline just in case the file doesn't end with one
    echo "" >> "$CONFIG_FILE"
    cat <<EOF >> "$CONFIG_FILE"
Host $HOST_ALIAS
HostName $HOSTNAME
User $USER
IdentityFile $KEY_FILE
StrictHostKeyChecking accept-new
EOF
fi

echo "Setup complete. You can now connect using: ssh $HOST_ALIAS"
