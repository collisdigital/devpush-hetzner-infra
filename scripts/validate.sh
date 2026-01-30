#!/bin/bash
set -e

echo "Running Terraform Format Check..."
terraform fmt -check -recursive

echo "Running Terraform Validate..."
terraform validate

echo "Validation successful!"