#!/bin/bash
set -e

echo "Verifying deployments..."
IFS=',' read -ra IPS <<< "${SERVER_IPS}"
for IP in "${IPS[@]}"; do
  echo "Checking $IP..."
  curl -s http://$IP
done
