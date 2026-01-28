#!/bin/bash
set -e

echo "Running terraform fmt -check..."
terraform fmt -check

echo "Running terraform init -backend=false..."
terraform init -backend=false

echo "Running terraform validate..."
terraform validate

echo "Done"
