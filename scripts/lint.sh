#!/bin/bash
set -e

echo "Running TFLint..."
tflint --init
tflint -f compact
echo "Done"
