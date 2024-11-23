#!/bin/bash
set -e

# Create inventory file
echo "[webservers]" > inventory.ini
IFS=',' read -ra IPS <<< "${SERVER_IPS}"
for IP in "${IPS[@]}"; do
  echo "$IP ansible_user=ubuntu ansible_ssh_private_key_file=ansible-key.pem" >> inventory.ini
done

echo -e "\n[all:vars]" >> inventory.ini
echo "ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> inventory.ini
echo "ansible_python_interpreter=/usr/bin/python3" >> inventory.ini

# Create playbook
cat > playbook.yml << EOF
---
- hosts: webservers
  become: yes
  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600
    
    - name: Install ${STACK_TYPE}
      apt:
        name: $([ "$STACK_TYPE" = "NGINX" ] && echo "nginx" || echo "apache2")
        state: present
    
    - name: Create test page
      copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head><title>Server Info</title></head>
          <body>
            <h1>Server is running!</h1>
            <p>Stack: ${STACK_TYPE}</p>
            <p>Host: {{ ansible_host }}</p>
          </body>
          </html>
        dest: /var/www/html/index.html
    
    - name: Ensure service is running
      service:
        name: $([ "$STACK_TYPE" = "NGINX" ] && echo "nginx" || echo "apache2")
        state: started
        enabled: yes
EOF
