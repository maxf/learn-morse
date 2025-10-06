#!/bin/bash

# Get the current distribution configuration
echo "Getting distribution configuration..."
aws cloudfront get-distribution-config --id E1BU4CWN6QEQ6X > dist-config.json

# Extract the ETag
ETAG=$(jq -r '.ETag' dist-config.json)
echo "ETag: $ETAG"

# Create a modified configuration with Enabled=false
echo "Creating disabled configuration..."
jq '.DistributionConfig.Enabled = false | del(.ETag)' dist-config.json > disabled-config.json

# Update the distribution to disable it
echo "Disabling distribution..."
aws cloudfront update-distribution --id E1BU4CWN6QEQ6X --if-match "$ETAG" --distribution-config file://disabled-config.json

echo "Distribution is being disabled. This process may take 15-30 minutes to complete."
echo "Once the distribution status shows as 'Deployed', you can delete it with:"
echo "aws cloudfront get-distribution-config --id E1BU4CWN6QEQ6X --query ETag --output text"
echo "aws cloudfront delete-distribution --id E1BU4CWN6QEQ6X --if-match <new-etag>"
