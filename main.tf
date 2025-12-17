# main.tf - Azure Landing Zone Implementation

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# ============================================================================
# DATA SOURCES
# ============================================================================

data "azurerm_client_config" "current" {}

# ============================================================================
# AZURE LANDING ZONE MANAGEMENT GROUPS
# ============================================================================

module "management_groups" {
  source = "./modules/management_groups"

  # Core configuration
  resource_prefix            = var.resource_prefix
  root_management_group_name = var.root_management_group_name

  # Management group names
  decommissioned_group_name = var.decommissioned_group_name
  landing_zones_group_name  = var.landing_zones_group_name
  platform_group_name       = var.platform_group_name
  sandboxes_group_name      = var.sandboxes_group_name
  prod_group_name           = var.prod_group_name
  non_prod_group_name       = var.non_prod_group_name
  connectivity_group_name   = var.connectivity_group_name
  identity_group_name       = var.identity_group_name
  management_group_name     = var.management_group_name

  # Subscription assignments
  connectivity_subscription_id = var.connectivity_subscription_id
  identity_subscription_id     = var.identity_subscription_id
  management_subscription_id   = var.management_subscription_id
}

# ============================================================================
# CONNECTIVITY RESOURCES (OPTIONAL)
# ============================================================================

module "connectivity" {
  count  = local.deploy_network ? 1 : 0
  source = "./modules/connectivity"

  # Basic configuration
  connectivity_rg_name = local.connectivity_rg_name
  location             = var.location
  tags                 = local.common_tags

  # Architecture selection
  deploy_hub_spoke = local.deploy_hub_spoke
  deploy_vwan      = local.deploy_vwan

  # Hub & Spoke configuration
  hub_vnet_name          = local.hub_vnet_name
  hub_vnet_address_space = var.hub_vnet_address_space
  hub_subnets            = var.hub_subnets

  # Virtual WAN configuration  
  virtual_wan_name             = local.virtual_wan_name
  virtual_hub_name             = local.virtual_hub_name
  virtual_hub_address_prefix   = var.virtual_hub_address_prefix
  deploy_express_route_gateway = var.deploy_express_route_gateway
  deploy_vpn_gateway           = var.deploy_vpn_gateway
  express_route_gateway_name   = local.express_route_gateway_name
  vpn_gateway_name             = local.vpn_gateway_name

  # Optional features
  deploy_azure_firewall = true # Can be enabled as needed
  deploy_azure_bastion  = true # Can be enabled as needed
}

# ============================================================================
# CORE SECURITY POLICIES (OPTIONAL)
# ============================================================================

module "core_policies" {
  count  = var.deploy_core_policies ? 1 : 0
  source = "./modules/core_policies"

  # Policy configuration
  deploy_core_policies    = var.deploy_core_policies
  policy_enforcement_mode = var.policy_enforcement_mode

  # Management group IDs (from management groups module)
  root_management_group_id          = module.management_groups.root_management_group_id
  platform_management_group_id      = module.management_groups.platform_group_id
  landing_zones_management_group_id = module.management_groups.landing_zones_group_id
  sandbox_management_group_id       = module.management_groups.sandboxes_group_id

  # Policy parameters
  allowed_locations        = [var.location] # Allow primary location by default
  required_environment_tag = "BingoHR-ALZ"

  # Policy initiative and exemptions
  create_policy_initiative  = false
  create_sandbox_exemptions = false
  sandbox_exemption_expiry  = null # No expiry by default

  # DINE configuration
  deploy_diagnostic_policies = true
  log_analytics_workspace_id = var.deploy_log_analytics_workspace ? (
    var.observability_environment == "prod" ? module.optional_resources.log_analytics_workspace_prod_id : module.optional_resources.log_analytics_workspace_nonprod_id
  ) : var.log_analytics_workspace_id
  dine_category_group         = "audit"
  policy_assignment_location  = var.location

  depends_on = [module.management_groups]
}

# ============================================================================
# OPTIONAL MANAGEMENT RESOURCES
# ============================================================================

module "optional_resources" {
  source = "./modules/optional_resources"

  # Deployment flags
  deploy_log_analytics_workspace = var.deploy_log_analytics_workspace
  deploy_automation_account      = var.deploy_automation_account
  deploy_data_collection_rules   = var.deploy_data_collection_rules
  deploy_managed_identity        = var.deploy_managed_identity

  # Basic configuration
  resource_prefix = var.resource_prefix
  location        = var.location

  # Log Analytics workspace names (from locals)
  log_analytics_workspace_prod_name    = local.log_analytics_workspace_prod_name
  log_analytics_workspace_nonprod_name = local.log_analytics_workspace_nonprod_name
}

# ============================================================================
# COMPUTE RESOURCES (VMs - OPTIONAL)
# ============================================================================

module "compute" {
  source = "./modules/compute"

  # Deployment flag
  deploy_compute_resources = var.deploy_compute_resources

  # Basic configuration
  resource_prefix = var.resource_prefix
  location        = var.location
  tags            = local.common_tags

  # VM configuration
  vm_size             = var.vm_size
  vm_os_type          = var.vm_os_type
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  ssh_public_key_path = var.ssh_public_key_path
  generate_ssh_key    = var.generate_ssh_key
  assign_public_ip    = var.assign_public_ip
  create_compute_vnet = var.create_compute_vnet
  existing_subnet_id  = var.existing_subnet_id

  # Azure Monitor configuration
  enable_azure_monitor       = var.enable_azure_monitor
  subscription_id            = data.azurerm_client_config.current.subscription_id
  log_analytics_workspace_id = var.deploy_log_analytics_workspace ? (
    var.observability_environment == "prod" ? module.optional_resources.log_analytics_workspace_prod_id : module.optional_resources.log_analytics_workspace_nonprod_id
  ) : var.log_analytics_workspace_id

  # Bastion subnet CIDR for NSG allow rules (auto from connectivity)
  bastion_source_cidr = try(module.connectivity[0].hub_subnet_cidrs["AzureBastionSubnet"], "")

  # Bastion private IP for NSG allow rules (default to Azure platform IP)
  bastion_private_ip = "168.63.129.16"
}

# ============================================================================
# DIAGNOSTIC SETTINGS FOR VM MONITORING
# ============================================================================

# Send VM metrics to Log Analytics Workspace
resource "azurerm_monitor_diagnostic_setting" "vm_diagnostics" {
  count              = var.deploy_compute_resources && var.enable_azure_monitor && var.deploy_log_analytics_workspace ? 1 : 0
  name               = "${var.resource_prefix}-vm-metrics"
  target_resource_id = var.vm_os_type == "linux" ? module.compute.vm_id : module.compute.vm_id

  log_analytics_workspace_id = var.observability_environment == "prod" ? module.optional_resources.log_analytics_workspace_prod_id : module.optional_resources.log_analytics_workspace_nonprod_id

  # Enable all platform metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }

  depends_on = [module.compute, module.optional_resources]
}

# ============================================================================
# DEPLOYMENT COMPLETED
# ============================================================================

# All Azure Landing Zone components have been deployed through the modules above:
# - Management Groups: Complete ALZ hierarchy
# - Connectivity: Hub & Spoke or Virtual WAN (optional)
# - Core Policies: Essential security controls (optional)  
# - Management Resources: Log Analytics and Automation (optional)
# - Compute: Virtual Machine instances with security groups and Azure Monitor (optional)