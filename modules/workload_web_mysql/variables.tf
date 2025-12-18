variable "env" {
  description = "Environment name (e.g., prod, nonprod)"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "vm_size" {
  description = "VM size for both web and mysql VMs"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "generate_ssh_key" {
  description = "Generate SSH key via Terraform"
  type        = bool
  default     = false
}

variable "assign_public_ip" {
  description = "Assign public IP to web VM"
  type        = bool
  default     = true
}

variable "create_vnet" {
  description = "Create a VNet for the workload"
  type        = bool
  default     = true
}

variable "existing_subnet_id" {
  description = "Existing subnet ID when not creating VNet"
  type        = string
  default     = ""
}

variable "bastion_source_cidr" {
  description = "CIDR of AzureBastionSubnet for SSH/RDP allow rules"
  type        = string
  default     = "VirtualNetwork"
}

variable "bastion_private_ip" {
  description = "Azure platform/Bastion private IP allowed for management"
  type        = string
  default     = "168.63.129.16"
}

variable "db_username" {
  description = "MySQL application user name"
  type        = string
  default     = "appuser"
}

variable "db_password" {
  description = "MySQL application user password"
  type        = string
  default     = "Passw0rd123!"
  sensitive   = true
}

variable "db_name" {
  description = "MySQL database name"
  type        = string
  default     = "appdb"
}
