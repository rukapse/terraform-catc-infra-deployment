# Terraform vSphere Catalyst Deployment

This repository contains Terraform scripts to automate the deployment of Cisco Catalyst Center and virtual network devices on a vSphere ESXi environment. The scripts define and manage network infrastructure components such as virtual switches, port groups, and virtual machines, ensuring a streamlined and repeatable deployment process.

## Project Description

This Terraform project performs the following tasks:
- **Defines ESXi vSwitch Resources:** Configures virtual switches on ESXi, optionally setting uplinks and specifying security settings such as promiscuous mode, MAC address changes, and forged transmits.
- **Creates ESXi Port Groups:** Sets up port groups on specified vSwitches and assigns VLAN IDs if provided.
- **Deploys Virtual Machines:** Uses OVF deployment to configure virtual machines, including network interfaces and storage options.
- **Manages Serial Ports on VMs:** Configures virtual serial ports for VMs requiring serial connections, utilizing PowerCLI for script execution on vSphere.

## Getting Started

### Prerequisites

1. **Install Terraform:**
   - Follow the instructions on the [Terraform website](https://www.terraform.io/downloads.html) to download and install Terraform for your operating system.

2. **Install PowerShell (for macOS):**
   - Open a terminal and execute the following command:
     ```bash
     brew install --cask powershell
     ```

### Repository Structure

- `main.tf`: Contains the main Terraform configuration for resources.
- `provider.tf`: Defines provider configurations, such as vSphere.
- `README.md`: This file, providing project details and instructions.
- `terraform.tfvars`: Contains variable values for configuration (modify this file for your setup).
- `variables.tf`: Defines input variables used in the Terraform configuration.

### Configuration

Modify the `terraform.tfvars` file to set up your environment-specific variables. This file is where you specify values for the variables defined in `variables.tf`.

### Basic Terraform Commands

- **Initialize the project:**
  - Run `terraform init` to initialize the Terraform working directory and download the necessary provider plugins.

- **Apply the configuration:**
  - Execute `terraform apply` to create and configure the specified resources. You will be prompted to confirm the action.

- **Destroy the infrastructure:**
  - Use `terraform destroy` to remove all resources defined in the Terraform configuration.

- **Refresh the state:**
  - Run `terraform refresh` to update the state file with the real infrastructure state without making changes to the resources.

### Debugging and Error Handling

To debug or specify variable files, use the `-var-file` option with the relevant Terraform commands:

```bash
terraform apply -var-file=terraform.tfvars
terraform destroy -var-file=terraform.tfvars
