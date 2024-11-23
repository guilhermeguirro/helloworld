#!/bin/bash
set -e

IFS=',' read -ra IPS <<< "${SERVER_IPS}"
for IP in "${IPS[@]}"; do
  echo "Waiting for SSH on $IP..."
  until ssh -i ansible-key.pem -o StrictHostKeyChecking=no ubuntu@$IP 'echo "SSH Ready"' 2>/dev/null; do
    sleep 5
  done
done
