#!/bin/bash
set -e

# Create security group
echo "Creating security group..."
SG_ID=$(aws ec2 create-security-group \
  --group-name "ansible-sg-${RUN_ID}" \
  --description "Security group for Ansible cluster" \
  --output json | jq -r '.GroupId')

echo "Security group created: ${SG_ID}"

aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 22, "ToPort": 22, "IpRanges": [{"CidrIp": "0.0.0.0/0"}]}]'

aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 80, "ToPort": 80, "IpRanges": [{"CidrIp": "0.0.0.0/0"}]}]'

# Create key pair
echo "Creating key pair..."
aws ec2 create-key-pair \
  --key-name "ansible-key-${RUN_ID}" \
  --query 'KeyMaterial' \
  --output text > ansible-key.pem
chmod 600 ansible-key.pem

# Launch instances and collect IPs
declare -a IPS
declare -a INSTANCE_IDS
echo "Launching instances..."

for i in $(seq 1 ${INSTANCE_COUNT}); do
  echo "Launching instance $i of ${INSTANCE_COUNT}..."
  
  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id ${UBUNTU_AMI} \
    --instance-type ${INSTANCE_TYPE} \
    --key-name "ansible-key-${RUN_ID}" \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=ansible-node-$i}]" \
    --output json | jq -r '.Instances[0].InstanceId')
  
  INSTANCE_IDS+=($INSTANCE_ID)
  echo "Instance $INSTANCE_ID launched"
  
  echo "Waiting for instance $INSTANCE_ID..."
  aws ec2 wait instance-running --instance-ids $INSTANCE_ID
  
  IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)
  
  IPS+=($IP)
  echo "ip_$i=$IP" >> "$GITHUB_OUTPUT"
done

# Save all IPs as a comma-separated list
IPS_STRING=$(IFS=,; echo "${IPS[*]}")
echo "all_ips=${IPS_STRING}" >> "$GITHUB_OUTPUT"

# Save instance IDs and security group ID for cleanup
echo "${SG_ID}" > security-group-id.txt
printf "%s\n" "${INSTANCE_IDS[@]}" > instance-ids.txt

echo "Infrastructure launch completed successfully"
echo "IPs: ${IPS_STRING}"
