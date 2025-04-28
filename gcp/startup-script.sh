#!/bin/bash
set -xe

# Update and install Docker
sudo apt-get update -y
sudo apt-get install -y docker.io

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add the SSH user (from Terraform) to the docker group
sudo usermod -aG docker sudheerpithaniofficial

# Pull and run the nginx container
sudo docker pull nginx
sudo docker run -d -p 8080:80 nginx

# Log success
echo "Startup script finished successfully." | sudo tee -a /var/log/startup-script-output.log

