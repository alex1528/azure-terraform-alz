# modules/optional_resources/variables.tf

variable "deploy_log_analytics_workspace" {
  description = "Set to true to deploy Log Analytics Workspaces (Prod and Non-Prod)"
  type        = bool
  default     = false
}

variable "deploy_automation_account" {
  description = "Set to true to deploy an Azure Automation Account"
  type        = bool
  default     = false
}

variable "deploy_data_collection_rules" {
  description = "Set to true to deploy Data Collection Rules"
  type        = bool
  default     = false
}

variable "deploy_managed_identity" {
  description = "Set to true to deploy a User Assigned Managed Identity"
  type        = bool
  default     = false
}

variable "location" {
  description = "Location for resource deployments"
  type        = string
}

variable "log_analytics_workspace_prod_name" {
  description = "Computed name for the production Log Analytics Workspace"
  type        = string
}

variable "log_analytics_workspace_nonprod_name" {
  description = "Computed name for the non-production Log Analytics Workspace"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for naming resources, used across resources for consistency"
  type        = string
}

# Defender for Cloud configuration
variable "enable_defender_for_cloud" {
  description = "Enable Microsoft Defender for Cloud at the subscription level"
  type        = bool
  default     = true
}

variable "defender_auto_provision" {
  description = "Deprecated by Azure: LA auto-provisioning cannot be enabled. If true, we only enforce 'Off' explicitly; default false to skip managing."
  type        = bool
  default     = false
}

variable "defender_tier" {
  description = "Defender pricing tier for resource types (Free or Standard)"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Free", "Standard"], var.defender_tier)
    error_message = "defender_tier must be either 'Free' or 'Standard'."
  }
}

variable "defender_plans" {
  description = "Set of Defender plans (resource types) to enable pricing for"
  type        = set(string)
  default     = [
    "VirtualMachines",
    "AppServices",
    "SqlServers",
    "StorageAccounts",
    "KubernetesService",
    "ContainerRegistry",
    "KeyVaults",
    "Arm",
    "Dns",
    "OpenSourceRelationalDatabases",
    "CosmosDbs"
  ]
}

variable "observability_environment" {
  description = "Select which LAW to bind with Defender: 'prod' or 'nonprod'"
  type        = string
  default     = "prod"
  validation {
    condition     = contains(["prod", "nonprod"], var.observability_environment)
    error_message = "observability_environment must be either 'prod' or 'nonprod'."
  }
}
