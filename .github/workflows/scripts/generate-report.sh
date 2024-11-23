#!/bin/bash
set -e

cat << EOF > report.md
# 🚀 Deployment Report

## Server Information
$(IFS=',' read -ra IPS <<< "${SERVER_IPS}"; for IP in "${IPS[@]}"; do echo "* http://$IP"; done)

## Configuration
* Stack: ${STACK_TYPE}
* Instance Type: ${INSTANCE_TYPE}
* Server Count: ${INSTANCE_COUNT}
EOF
