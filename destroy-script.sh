#!/usr/bin/env bash
# deploy-all.sh
set -e

echo "[INFO] Destroying deployment to AWS and GCP..."

# AWS
cd ~/multi-cloud-deployment/aws/
terraform destroy -auto-approve

# GCP
cd ~/multi-cloud-deployment/gcp/
terraform destroy -auto-approve

echo "[INFO] Both AWS and GCP destroyed successfully."

