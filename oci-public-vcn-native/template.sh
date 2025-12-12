#!/bin/bash

export LB_PUBLIC_IP=""
export LB_PUBLIC_SUBNET_ID=""
export LB_PUBLIC_SUBNET_CIDR=""
export FRONTEND_NSG_ID=""
export BACKEND_NSG_ID=""
export CERTIFICATE_SECRET_NAME=""
export ECHO_IMAGE="registry.k8s.io/echoserver:1.8"      # registry.k8s.io/echoserver-arm:1.8 if using arm nodes

# Create template directory if it doesn't exist
mkdir -p ../template

# Process all .yml files in the current directory
for file in *.yml; do
  if [ "$file" != "template.sh" ]; then
    envsubst < "$file" > "../template/$file"
    echo "Processed $file -> ../template/$file"
  fi
done

echo "Templating complete. Files generated in ../template/"
