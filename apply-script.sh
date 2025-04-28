#!/usr/bin/env bash
# deploy-all.sh
set -e

echo "[INFO] Starting deployment to AWS and GCP..."

# AWS
cd ~/multi-cloud-deployment/aws/
terraform init
terraform apply -auto-approve

# GCP
cd ~/multi-cloud-deployment/gcp/
terraform init
terraform apply -auto-approve

echo "[INFO] Both AWS and GCP deployments completed successfully."
