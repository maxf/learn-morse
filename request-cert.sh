#!/bin/bash

# Request a wildcard certificate for e010101.org
aws acm request-certificate \
  --region us-east-1 \
  --domain-name e010101.org \
  --subject-alternative-names "*.e010101.org" \
  --validation-method DNS

echo "Certificate requested. Check the AWS ACM console for the new certificate ARN."
echo "Once you have the new certificate ARN, update the acm_certificate_arn value in main.tf"
