# modules/compute/variables.tf - Compute Module Variables

variable "deploy_compute_resources" {
  description = "Whether to deploy compute resources (VM instance)"
  type        = bool
  default     = false
}

variable "resource_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "vm_size" {
  description = "Virtual machine size (4 vCPU, 8GB RAM options: Standard_B2s, Standard_D2s_v3)"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "vm_os_type" {
  description = "Operating system type: 'linux' or 'windows'"
  type        = string
  default     = "linux"

  validation {
    condition     = var.vm_os_type == "linux" || var.vm_os_type == "windows"
    error_message = "vm_os_type must be either 'linux' or 'windows'."
  }
}

variable "admin_username" {
  description = "Administrator username for VM"
  type        = string
  default     = "azureuser"
  sensitive   = true
}

variable "admin_password" {
  description = "Administrator password for Windows VM (set when vm_os_type = windows)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file (for Linux VM). Ignored if generate_ssh_key = true"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "generate_ssh_key" {
  description = "Whether to generate SSH key pair via Terraform (private key will be in state file)"
  type        = bool
  default     = false
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP address to the VM"
  type        = bool
  default     = true
}

variable "create_compute_vnet" {
  description = "Whether to create a new VNet for compute resources"
  type        = bool
  default     = true
}

variable "existing_subnet_id" {
  description = "Existing subnet ID to use for VM (when create_compute_vnet = false)"
  type        = string
  default     = ""
}

# ============================================================================
# AZURE MONITOR CONFIGURATION
# ============================================================================

variable "enable_azure_monitor" {
  description = "Whether to enable Azure Monitor Agent and diagnostics on the VM"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for VM diagnostics and metrics"
  type        = string
  default     = ""
}

variable "subscription_id" {
  description = "Azure subscription ID (required for Monitor role assignments)"
  type        = string
  default     = ""
}

# ============================================================================
# BASTION SOURCE CIDR FOR NSG RULES
# ============================================================================

variable "bastion_source_cidr" {
  description = "CIDR of AzureBastionSubnet to allow SSH/RDP access to VMs via Bastion"
  type        = string
  default     = ""
}

variable "bastion_private_ip" {
  description = "Azure Bastion management private IP (default 168.63.129.16) to allow SSH/RDP from this IP"
  type        = string
  default     = "168.63.129.16"
}

