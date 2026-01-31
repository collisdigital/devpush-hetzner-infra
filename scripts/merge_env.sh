#!/bin/bash
set -e

# Update .env with custom values while preserving auto-generated secrets
TARGET="/var/lib/devpush/.env"
SOURCE="/etc/opt/devpush/.env.custom

# Read source file line by line
while IFS= read -r line || [ -n "$line" ]; do
  # Skip comments and empty lines
  if [[ "$line" =~ ^# ]] || [[ -z "$line" ]]; then
    continue
  fi
  
  # Extract key
  key=$(echo "$line" | cut -d '=' -f 1)
  
  # If key exists in the target, update it
  if grep -q "^$key=" "$TARGET"; then
    # Escape special characters for sed
    value=$(echo "$line" | cut -d '=' -f 2-)
    escaped_value=$(printf '%s\n' "$value" | sed -e 's/[\/&]/\\&/g')
    sed -i "s|^$key=.*|$key=$escaped_value|" "$TARGET"
  else
    # Append if not found
    echo "$line" >> "$TARGET"
  fi
done < "$SOURCE"
