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
  default     = "Standard_D2s_v5"
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

variable "enable_aad_login" {
  description = "Enable AAD Login VM extension on both VMs"
  type        = bool
  default     = false
}

variable "web_vm_zone" {
  description = "Availability Zone for the Web VM (e.g., '1', '2', '3'). Leave null for no specific zone."
  type        = string
  default     = null
}

variable "mysql_vm_zone" {
  description = "Availability Zone for the MySQL VM (e.g., '1', '2', '3'). Leave null for no specific zone."
  type        = string
  default     = null
}

variable "spoke_route_table_id" {
  description = "Optional route table ID to associate with the workload subnet to force egress through the hub firewall"
  type        = string
  default     = ""
}

# Addressing (parameterized to avoid overlaps across environments)
variable "vnet_address_space" {
  description = "Address space for the workload VNet"
  type        = list(string)
  default     = ["10.11.0.0/16"]
}

variable "subnet_prefixes" {
  description = "Address prefixes for the workload subnet(s)"
  type        = list(string)
  default     = ["10.11.1.0/24"]
}
