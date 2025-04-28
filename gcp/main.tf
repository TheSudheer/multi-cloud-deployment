# --- Variables ---

variable "network_name" {
  description = "The name for the VPC network."
  type        = string
  default     = "myapp-vpc-network"
}

variable "subnetwork_name" {
  description = "The name for the subnetwork."
  type        = string
  default     = "myapp-subnet"
}

variable "subnet_ip_cidr_range" {
  description = "The CIDR block for the subnetwork."
  type        = string
}

variable "env_prefix" {
  description = "A prefix (e.g., 'dev', 'prod') used for naming/labeling resources."
  type        = string
}

variable "my_ip" {
  description = "Your public IP address in CIDR notation (e.g., 'x.x.x.x/32') for SSH access."
  type        = string
}

variable "machine_type" {
  description = "The Compute Engine machine type (e.g., 'e2-micro')."
  type        = string
}

variable "private_key_location" {
  description = "The file path to your private SSH key."
  type        = string
}

# Removed Pub key file

variable "image_project" {
  description = "The GCP project for the VM image (e.g., 'ubuntu-os-cloud')."
  type        = string
  default     = "ubuntu-os-cloud"
}

variable "image_family" {
  description = "The image family for the VM (e.g., 'ubuntu-2404-lts-amd64')."
  type        = string
  default     = "ubuntu-2404-lts-amd64"
}

variable "ssh_username" {
  description = "The SSH username for accessing the instance."
  type        = string
}

# --- Resources ---

# Create a custom VPC Network
resource "google_compute_network" "vpc_network" {
  name                    = "${var.env_prefix}-${var.network_name}"
  auto_create_subnetworks = false # I want custom subnetworks
}

# Create a Subnetwork within the VPC Network
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.env_prefix}-${var.subnetwork_name}"
  ip_cidr_range = var.subnet_ip_cidr_range
  network       = google_compute_network.vpc_network.id
}

# Firewall rule to allow SSH (port 22) from your IP
resource "google_compute_firewall" "allow_ssh" {
  name      = "${var.env_prefix}-allow-ssh"
  network   = google_compute_network.vpc_network.self_link
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.my_ip]
  # Apply this rule to instances with the 'ssh-access' tag
  target_tags = ["${var.env_prefix}-vm"]
}

# Firewall rule to allow traffic on port 8080 from your IP
# Change source_ranges to ["0.0.0.0/0"] for public access
resource "google_compute_firewall" "allow_web_8080" {
  name      = "${var.env_prefix}-allow-web-8080"
  network   = google_compute_network.vpc_network.self_link
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = [var.my_ip]
  # Apply this rule to instances with the 'web-access' tag
  target_tags = ["${var.env_prefix}-vm"]
}

# Note: GCP allows all egress traffic by default, so no explicit egress rule is needed
# unless you want to restrict outbound traffic.

# Get the latest image from the specified family and project
data "google_compute_image" "vm_image" {
  family  = var.image_family
  project = var.image_project
}

# Create the Compute Engine instance
resource "google_compute_instance" "myapp_server" {
  name         = "${var.env_prefix}-myapp-server"
  machine_type = var.machine_type

  # Add tags for firewall rules
  tags = ["${var.env_prefix}-vm"]

  # Define the boot disk using the selected image
  boot_disk {
    initialize_params {
      image = data.google_compute_image.vm_image.self_link
      size  = 15 # Optional: specify disk size in GB
    }
  }

  # Define the network interface, connecting to the subnetwork
  # and requesting an ephemeral public IP
  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    enable-oslogin = "FALSE"
  }

  # Define labels (similar to AWS Tags)
  labels = {
    environment = var.env_prefix
    app         = "myapp"
  }

  # Optional: Allow stopping/starting the instance without deleting it
  allow_stopping_for_update = true

  # --- SSH connection info for provisioners ---
  connection {
    type        = "ssh"
    host        = self.network_interface[0].access_config[0].nat_ip
    user        = var.ssh_username
    private_key = file(pathexpand(var.private_key_location))
    
  }

  # --- Copy my script ---
  provisioner "file" {
    source      = "${path.module}/startup-script.sh"
    destination = "/tmp/startup-script.sh"
  }

  # --- Then run it ---
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/startup-script.sh",
      "sudo /tmp/startup-script.sh"
    ]
  }
}

# --- Outputs ---

output "instance_name" {
  description = "The name of the Compute Engine instance."
  value       = google_compute_instance.myapp_server.name
}

output "instance_public_ip" {
  description = "The public IP address of the Compute Engine instance."
  value       = google_compute_instance.myapp_server.network_interface[0].access_config[0].nat_ip
}

output "instance_network" {
  description = "The network the instance is attached to."
  value       = google_compute_network.vpc_network.self_link
}

output "instance_image" {
  description = "The image used for the instance's boot disk."
  value       = data.google_compute_image.vm_image.self_link
}

output "ssh_command_example" {
  description = "Example SSH command (replace USERNAME with the one used in metadata)."
  value       = "ssh -i ${var.private_key_location} var.ssh_username@${google_compute_instance.myapp_server.network_interface[0].access_config[0].nat_ip}"
}
