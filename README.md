# Multi-Cloud Web Server Deployment using Terraform (AWS + GCP)

## Objective

This project demonstrates the automated provisioning of web server infrastructure across two major cloud providers, Amazon Web Services (AWS) and Google Cloud Platform (GCP), using Terraform. The goal is to deploy NGINX web servers simultaneously on both platforms and validate the setup efficiently.

*(Based on the initial project description)*

## Architecture Overview

The infrastructure consists of the following components deployed in parallel on both AWS and GCP:

1.  **Networking:** A custom Virtual Private Cloud (VPC) on AWS and a VPC Network on GCP, each with a dedicated subnet. Internet Gateways and Route Tables (AWS) or default routes (GCP) are configured for internet access.
2.  **Compute:** One EC2 instance on AWS and one Compute Engine instance on GCP, running Amazon Linux 2 and Ubuntu LTS respectively.
3.  **Security:** Security Groups (AWS) and Firewall Rules (GCP) are configured to allow:
    * SSH access (TCP port 22) only from a specified IP address (`my_ip` variable).
    * HTTP access (TCP port 8080) only from a specified IP address (`my_ip` variable).
    * All egress traffic (restricted to `my_ip` in the provided AWS config, fully open in GCP config).
4.  **Web Server:** NGINX is automatically installed and started on both instances using startup scripts (`entry-script.sh` for AWS, `startup-script.sh` for GCP). NGINX listens on port **8080**.

**(Placeholder for Infrastructure Diagram)**
![Infrastructure Diagram](screenshots/infrastructure.png)
*(Ensure `screenshots/infrastructure.png` contains your architecture diagram)*

## Technologies Used

* **Infrastructure as Code:** Terraform
* **Cloud Providers:**
    * Amazon Web Services (AWS) - (Utilizing Free Tier where applicable)
    * Google Cloud Platform (GCP) - (Utilizing Free Tier where applicable)
* **Web Server:** NGINX
* **Operating Systems:** Amazon Linux 2 (AWS), Ubuntu LTS (GCP)
* **Scripting:** Bash (for deployment/cleanup and instance startup)

## Project Structure

```
.
├── apply-script.sh       # Script to deploy infrastructure on both clouds
├── destroy-script.sh     # Script to destroy infrastructure on both clouds
├── aws/                  # AWS specific resources
│   ├── entry-script.sh   # Startup script for AWS EC2 instance (installs NGINX)
│   ├── main.tf           # AWS resource definitions
│   ├── providers.tf      # AWS provider configuration
│   └── terraform.tfvars  # AWS variable values (User configured)
├── gcp/                  # GCP specific resources
│   ├── main.tf           # GCP resource definitions
│   ├── providers.tf      # GCP provider configuration
│   ├── service_account/
│   │   └── keys.json     # GCP Service Account Key (User configured)
│   ├── startup-script.sh # Startup script for GCP instance (installs NGINX)
│   └── terraform.tfvars  # GCP variable values (User configured)
└── screenshots/          # Contains validation screenshots
    ├── aws.png           # Screenshot of AWS Console showing EC2 instance
    ├── gcp.png           # Screenshot of GCP Console showing Compute Engine instance
    └── with-domain-name.png # Screenshot showing access via local hostname
```

## Prerequisites

Before running the deployment, ensure you have the following installed and configured:

1.  **Terraform CLI:** [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
2.  **AWS Account & Credentials:**
    * An AWS account (Free Tier eligible recommended).
    * AWS CLI installed and configured with credentials (`aws configure`).
    * An SSH Key Pair generated in AWS. The public key file path is needed for `terraform.tfvars`.
3.  **GCP Account & Credentials:**
    * A GCP account (Free Tier eligible recommended).
    * Google Cloud SDK installed and authenticated (`gcloud auth login`, `gcloud config set project YOUR_PROJECT_ID`).
    * A GCP Service Account with necessary permissions (e.g., Compute Admin) and its key file (`keys.json`) downloaded.
4.  **Git (Optional):** To clone this repository.

## Configuration

1.  **Clone the Repository (Optional):**
    ```bash
    git clone <your-repository-url>
    cd multi-cloud-deployment
    ```
2.  **Configure AWS Variables:**
    * Edit the `aws/terraform.tfvars` file.
    * Provide values for `vpc_cidr_block`, `subnet_cidr_block`, `avail_zone`, `env_prefix`, `my_ip` (your public IP in CIDR notation, e.g., "x.x.x.x/32"), `instance_type`, and `public_key_location` (path to your `.pub` file).
3.  **Configure GCP Variables:**
    * Edit the `gcp/terraform.tfvars` file.
    * Provide values for `subnet_ip_cidr_range`, `env_prefix`, `my_ip` (your public IP in CIDR notation), `machine_type`, `private_key_location` (path to your private SSH key corresponding to the AWS public key, if reusing, otherwise adjust GCP config for separate keys), and `ssh_username`.
    * Place your downloaded GCP Service Account key file in `gcp/service_account/keys.json`.
4.  **Configure Local Hostname Simulation:**
    * This project simulates accessing the deployed web servers via a local domain name using the `/etc/hosts` file. **Note:** This method provides simple hostname mapping for local testing and does *not* involve DNSMasq, dynamic health checks, or automatic failover as might be implied by the original project description's advanced goals.
    * You will need `sudo` privileges to edit this file.
    * After deployment, manually add entries for *both* the AWS and GCP instance public IPs to your local `/etc/hosts` file, mapping them to the desired hostname (e.g., `multi-cloud.local`).
        ```bash
        # Example /etc/hosts entries (Replace IPs with actual output IPs)
        # sudo nano /etc/hosts
        <AWS_INSTANCE_PUBLIC_IP> multi-cloud.local
        <GCP_INSTANCE_PUBLIC_IP> multi-cloud.local
        ```
    * **Important:** Mapping the same hostname to multiple IPs in `/etc/hosts` leads to behavior where typically only one IP (often the last entry) is resolved. This setup demonstrates hostname mapping but not load balancing or failover.

## Deployment

A convenience script `apply-script.sh` is provided to automate the deployment process for both clouds sequentially.

1.  **Ensure the script is executable:**
    ```bash
    chmod +x apply-script.sh
    ```
2.  **Run the deployment script:**
    ```bash
    ./apply-script.sh
    ```
    This script will:
    * Navigate into the `aws` directory.
    * Run `terraform init` and `terraform apply -auto-approve`.
    * Navigate into the `gcp` directory.
    * Run `terraform init` and `terraform apply -auto-approve`.
    * Wait for both apply processes to complete. Terraform will output the public IP addresses for each instance.

## Validation

1.  **Check Terraform Output:** Note the `ec2_public_ip` from the AWS apply and `instance_public_ip` from the GCP apply.
2.  **Verify Cloud Consoles:**
    * Log in to your AWS console and verify the EC2 instance is running. (See `screenshots/aws.png`)
    * Log in to your GCP console and verify the Compute Engine instance is running. (See `screenshots/gcp.png`)
3.  **Direct IP Access:** Test accessing NGINX directly via the public IPs on port **8080**:
    * `http://<AWS_INSTANCE_PUBLIC_IP>:8080`
    * `http://<GCP_INSTANCE_PUBLIC_IP>:8080`
    * You should see the default NGINX welcome page for both.
4.  **Local Hostname Access:**
    * Ensure you have updated your `/etc/hosts` file as described in the Configuration section.
    * Access the service via the local hostname on port **8080**:
        `http://multi-cloud.local:8080`
    * This should resolve to one of the NGINX welcome pages (typically the one corresponding to the last entry in `/etc/hosts` for that name). (See `screenshots/with-domain-name.png`)

## Cleanup

To destroy all deployed infrastructure and avoid ongoing costs, use the provided cleanup script.

1.  **Ensure the script is executable:**
    ```bash
    chmod +x destroy-script.sh
    ```
2.  **Run the destruction script:**
    ```bash
    ./destroy-script.sh
    ```
    This script will:
    * Navigate into the `aws` directory and run `terraform destroy -auto-approve`.
    * Navigate into the `gcp` directory and run `terraform destroy -auto-approve`.
3.  **Remove Hosts Entry:** Manually remove the `multi-cloud.local` entries from your `/etc/hosts` file.

## Screenshots

* **`screenshots/aws.png`**: Shows the running EC2 instance in the AWS Management Console.
* **`screenshots/gcp.png`**: Shows the running Compute Engine instance in the Google Cloud Console.
* **`screenshots/with-domain-name.png`**: Demonstrates accessing the NGINX service using the local hostname (`multi-cloud.local:8080`) defined in the `/etc/hosts` file.
* **`screenshots/infrastructure.png`**: Visual diagram of the deployed architecture across AWS and GCP.

## Future Improvements

* **Centralized Terraform State:** Utilize Terraform Cloud or an S3/GCS backend for state management instead of local state files.
* **Unified Terraform Code:** Refactor using Terraform modules or workspaces to manage both clouds from a single configuration root.
* **Robust Health Checks & Failover:** Implement proper cloud load balancers (AWS ALB/NLB, GCP Cloud Load Balancer) with active health checks. For local simulation, use DNSMasq with a health-checking script to dynamically update local DNS resolution for failover.
* **CI/CD Integration:** Automate the deployment and destruction process using a CI/CD pipeline (e.g., GitHub Actions, GitLab CI).
* **Security Enhancements:** Use more granular permissions, secrets management for keys, and potentially private networking options.
```
