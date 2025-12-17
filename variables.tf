# Root-level variables.tf - Azure Landing Zone Terraform Implementation

# ============================================================================
# CORE ALZ CONFIGURATION
# ============================================================================

variable "root_management_group_name" {
  description = "Display name of the root management group under the tenant root group"
  type        = string
  validation {
    condition     = length(var.root_management_group_name) > 0
    error_message = "Root management group name cannot be empty."
  }
}

variable "resource_prefix" {
  description = "Prefix for resource names (e.g., contoso, myorg)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{2,10}$", var.resource_prefix))
    error_message = "Resource prefix must be 2-10 characters, lowercase letters and numbers only."
  }
}

variable "location" {
  description = "Primary Azure region for resources deployment"
  type        = string
  default     = "westus3"
}

# ============================================================================
# SUBSCRIPTION ASSIGNMENTS
# ============================================================================

variable "connectivity_subscription_id" {
  description = "Subscription ID to assign to the Connectivity management group (optional)"
  type        = string
  default     = null
  validation {
    condition     = var.connectivity_subscription_id == null || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.connectivity_subscription_id))
    error_message = "Connectivity subscription ID must be a valid GUID or null."
  }
}

variable "identity_subscription_id" {
  description = "Subscription ID to assign to the Identity management group (optional)"
  type        = string
  default     = null
  validation {
    condition     = var.identity_subscription_id == null || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.identity_subscription_id))
    error_message = "Identity subscription ID must be a valid GUID or null."
  }
}

variable "management_subscription_id" {
  description = "Subscription ID to assign to the Management management group (optional)"
  type        = string
  default     = null
  validation {
    condition     = var.management_subscription_id == null || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.management_subscription_id))
    error_message = "Management subscription ID must be a valid GUID or null."
  }
}

# ============================================================================
# NETWORKING ARCHITECTURE CHOICE
# ============================================================================

variable "network_architecture" {
  description = "Choose network architecture: 'hub_spoke' for traditional hub and spoke, 'vwan' for Virtual WAN, or 'none' for no connectivity resources"
  type        = string
  default     = "hub_spoke"
  validation {
    condition     = contains(["hub_spoke", "vwan", "none"], var.network_architecture)
    error_message = "Network architecture must be one of: hub_spoke, vwan, or none."
  }
}

variable "deploy_connectivity_resources" {
  description = "Deploy connectivity resources (VNet, Virtual WAN, etc.)"
  type        = bool
  default     = true
}

# ============================================================================
# HUB & SPOKE CONFIGURATION
# ============================================================================

variable "hub_vnet_address_space" {
  description = "Address space for the hub virtual network (used when network_architecture = 'hub_spoke')"
  type        = list(string)
  default     = ["10.0.0.0/22"]
}

variable "hub_subnets" {
  description = "Map of hub subnet names to their CIDR blocks"
  type = map(object({
    address_prefixes = list(string)
    delegations      = optional(list(string), [])
  }))
  default = {
    "snet-shared-services" = {
      address_prefixes = ["10.0.0.0/24"]
    }
    "snet-management" = {
      address_prefixes = ["10.0.1.0/24"]
    }
    "AzureBastionSubnet" = {
      address_prefixes = ["10.0.2.0/26"]
    }
    "AzureFirewallSubnet" = {
      address_prefixes = ["10.0.3.0/26"]
    }
  }
}

# ============================================================================
# VIRTUAL WAN CONFIGURATION
# ============================================================================

variable "virtual_wan_name" {
  description = "The name of the Virtual WAN (used when network_architecture = 'vwan')"
  type        = string
  default     = "alz-vwan"
}

variable "virtual_hub_address_prefix" {
  description = "Address prefix for the virtual hub (used when network_architecture = 'vwan')"
  type        = string
  default     = "10.0.0.0/24"
}

variable "deploy_express_route_gateway" {
  description = "Deploy ExpressRoute gateway in Virtual WAN hub"
  type        = bool
  default     = false
}

variable "deploy_vpn_gateway" {
  description = "Deploy VPN gateway in Virtual WAN hub"
  type        = bool
  default     = false
}

# ============================================================================
# AZURE BASTION CONFIGURATION
# ============================================================================

variable "deploy_azure_bastion" {
  description = "Deploy Azure Bastion for secure VM access (Hub & Spoke only)"
  type        = bool
  default     = false
}

# ============================================================================
# MANAGEMENT GROUP CUSTOMIZATION
# ============================================================================

variable "decommissioned_group_name" {
  description = "Display name for the Decommissioned management group"
  type        = string
  default     = "Decommissioned"
}

variable "landing_zones_group_name" {
  description = "Display name for the Landing Zones management group"
  type        = string
  default     = "Landing Zones"
}

variable "platform_group_name" {
  description = "Display name for the Platform management group"
  type        = string
  default     = "Platform"
}

variable "sandboxes_group_name" {
  description = "Display name for the Sandboxes management group"
  type        = string
  default     = "Sandboxes"
}

variable "prod_group_name" {
  description = "Display name for the Production management group under Landing Zones"
  type        = string
  default     = "Production"
}

variable "non_prod_group_name" {
  description = "Display name for the Non-Production management group under Landing Zones"
  type        = string
  default     = "Non-Production"
}

variable "connectivity_group_name" {
  description = "Display name for the Connectivity management group under Platform"
  type        = string
  default     = "Connectivity"
}

variable "identity_group_name" {
  description = "Display name for the Identity management group under Platform"
  type        = string
  default     = "Identity"
}

variable "management_group_name" {
  description = "Display name for the Management management group under Platform"
  type        = string
  default     = "Management"
}

# ============================================================================
# POLICY CONFIGURATION
# ============================================================================

variable "deploy_core_policies" {
  description = "Deploy core security and compliance policies"
  type        = bool
  default     = true
}

variable "policy_enforcement_mode" {
  description = "Policy enforcement mode: 'DoNotEnforce' for audit mode, 'Default' for enforce mode"
  type        = string
  default     = "DoNotEnforce"
  validation {
    condition     = contains(["DoNotEnforce", "Default"], var.policy_enforcement_mode)
    error_message = "Policy enforcement mode must be either 'DoNotEnforce' or 'Default'."
  }
}

# ============================================================================
# OPTIONAL MANAGEMENT RESOURCES
# ============================================================================

variable "deploy_log_analytics_workspace" {
  description = "Deploy Log Analytics Workspaces for centralized logging"
  type        = bool
  default     = true
}

variable "deploy_automation_account" {
  description = "Deploy Azure Automation Account for management tasks"
  type        = bool
  default     = true
}

variable "deploy_data_collection_rules" {
  description = "Deploy Data Collection Rules for Azure Monitor"
  type        = bool
  default     = false
}

variable "deploy_managed_identity" {
  description = "Deploy User Assigned Managed Identity for service authentication"
  type        = bool
  default     = false
}

# ============================================================================
# RESOURCE TAGGING
# ============================================================================

variable "tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "ALZ"
    ManagedBy   = "Terraform"
    Framework   = "Azure-Landing-Zones"
    CreatedBy   = "ALZ-Terraform-Accelerator"
  }
}

variable "org_name" {
  description = "Organization name for resource naming conventions"
  type        = string
  default     = "alz"
  validation {
    condition     = can(regex("^[a-z0-9]{2,10}$", var.org_name))
    error_message = "Organization name must be 2-10 characters, lowercase letters and numbers only."
  }
}

# ============================================================================
# COMPUTE RESOURCES (VM CONFIGURATION)
# ============================================================================

variable "deploy_compute_resources" {
  description = "Whether to deploy compute resources (VM instance)"
  type        = bool
  default     = false
}

variable "vm_size" {
  description = "Virtual machine size (4 vCPU, 8GB RAM options: Standard_B2s, Standard_D2s_v3)"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "vm_os_type" {
  description = "Operating system type for VM: 'linux' (Ubuntu) or 'windows' (Windows Server 2022)"
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
  description = "Administrator password for Windows VM (required when vm_os_type = windows)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file for Linux VM (e.g., ~/.ssh/id_rsa.pub). Ignored when generate_ssh_key = true."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "generate_ssh_key" {
  description = "Whether to generate SSH key pair via Terraform (private key will be in state file). If false, uses ssh_public_key_path. Recommended: false for production."
  type        = bool
  default     = false
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP address to the VM"
  type        = bool
  default     = true
}

variable "create_compute_vnet" {
  description = "Whether to create a new VNet for compute resources (set false to use existing subnet)"
  type        = bool
  default     = true
}

variable "existing_subnet_id" {
  description = "Existing subnet ID to use for VM deployment (when create_compute_vnet = false)"
  type        = string
  default     = ""
}

# ============================================================================
# AZURE MONITOR CONFIGURATION
# ============================================================================

variable "enable_azure_monitor" {
  description = "Whether to enable Azure Monitor Agent on VMs for metrics collection"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Custom Log Analytics Workspace ID (if not using the automatically created one)"
  type        = string
  default     = ""
}

# ============================================================================
# OBSERVABILITY CONFIGURATION
# ============================================================================

variable "observability_environment" {
  description = "Select which Log Analytics workspace to use when multiple are created: 'prod' or 'nonprod'"
  type        = string
  default     = "prod"
  validation {
    condition     = contains(["prod", "nonprod"], var.observability_environment)
    error_message = "observability_environment must be either 'prod' or 'nonprod'."
  }
}