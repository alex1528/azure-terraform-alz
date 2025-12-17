# outputs.tf - Azure Landing Zone Outputs

# ============================================================================
# MANAGEMENT GROUP OUTPUTS
# ============================================================================

output "root_management_group_id" {
  description = "ID of the root management group"
  value       = module.management_groups.root_management_group_id
}

# Level 1 Management Groups
output "decommissioned_group_id" {
  description = "ID of the Decommissioned management group"
  value       = module.management_groups.decommissioned_group_id
}

output "landing_zones_group_id" {
  description = "ID of the Landing Zones management group"
  value       = module.management_groups.landing_zones_group_id
}

output "platform_group_id" {
  description = "ID of the Platform management group"
  value       = module.management_groups.platform_group_id
}

output "sandboxes_group_id" {
  description = "ID of the Sandboxes management group"
  value       = module.management_groups.sandboxes_group_id
}

# Level 2 Management Groups - Landing Zones
output "prod_group_id" {
  description = "ID of the Production management group under Landing Zones"
  value       = module.management_groups.prod_group_id
}

output "non_prod_group_id" {
  description = "ID of the Non-Production management group under Landing Zones"
  value       = module.management_groups.non_prod_group_id
}

# Level 2 Management Groups - Platform
output "connectivity_group_id" {
  description = "ID of the Connectivity management group under Platform"
  value       = module.management_groups.connectivity_group_id
}

output "identity_group_id" {
  description = "ID of the Identity management group under Platform"
  value       = module.management_groups.identity_group_id
}

output "management_group_id" {
  description = "ID of the Management management group under Platform"
  value       = module.management_groups.management_group_id
}

# ============================================================================
# CONNECTIVITY OUTPUTS (OPTIONAL)
# ============================================================================

output "connectivity_resource_group_name" {
  description = "Name of the connectivity resource group"
  value       = local.deploy_network ? module.connectivity[0].connectivity_resource_group_name : null
}

output "hub_vnet_id" {
  description = "ID of the hub virtual network (Hub & Spoke architecture)"
  value       = local.deploy_hub_spoke ? module.connectivity[0].hub_vnet_id : null
}

output "hub_vnet_name" {
  description = "Name of the hub virtual network (Hub & Spoke architecture)"
  value       = local.deploy_hub_spoke ? module.connectivity[0].hub_vnet_name : null
}

output "virtual_wan_id" {
  description = "ID of the Virtual WAN (Virtual WAN architecture)"
  value       = local.deploy_vwan ? module.connectivity[0].virtual_wan_id : null
}

output "virtual_hub_id" {
  description = "ID of the Virtual Hub (Virtual WAN architecture)"
  value       = local.deploy_vwan ? module.connectivity[0].virtual_hub_id : null
}

output "hub_subnet_ids" {
  description = "Map of hub subnet names to their IDs"
  value       = local.deploy_hub_spoke ? module.connectivity[0].hub_subnet_ids : {}
}

# ============================================================================
# POLICY OUTPUTS (OPTIONAL)
# ============================================================================

output "core_security_policies_deployed" {
  description = "Summary of deployed core security policies"
  value       = var.deploy_core_policies ? module.core_policies[0].deployed_policies_summary : null
}

output "platform_policy_assignments" {
  description = "Map of platform-level policy assignment names to their IDs"
  value       = var.deploy_core_policies ? module.core_policies[0].platform_policy_assignment_ids : {}
}

output "landing_zones_policy_assignments" {
  description = "Map of landing zones policy assignment names to their IDs"
  value       = var.deploy_core_policies ? module.core_policies[0].landing_zones_policy_assignment_ids : {}
}

# ============================================================================
# MANAGEMENT RESOURCE OUTPUTS (OPTIONAL)
# ============================================================================

output "management_resource_group_name" {
  description = "Name of the resource group created for optional resources"
  value       = module.optional_resources.management_resource_group_name
}

# ============================================================================
# SUMMARY OUTPUTS
# ============================================================================

output "deployment_summary" {
  description = "Summary of deployed Azure Landing Zone components"
  value = {
    management_groups_deployed      = true
    network_architecture            = var.network_architecture
    connectivity_resources_deployed = local.deploy_network
    core_policies_deployed          = var.deploy_core_policies
    policy_enforcement_mode         = var.policy_enforcement_mode
    log_analytics_deployed          = var.deploy_log_analytics_workspace
    automation_account_deployed     = var.deploy_automation_account
    location                        = var.location
    resource_prefix                 = var.resource_prefix
  }
}

output "next_steps" {
  description = "Recommended next steps after deployment"
  value = [
    "1. Review policy compliance in Azure Policy blade",
    "2. Assign workload subscriptions to appropriate management groups",
    "3. Deploy spoke VNets and connect to hub infrastructure",
    "4. Configure additional monitoring and alerting as needed",
    local.deploy_network ? "5. Test connectivity between hub and future spoke networks" : "5. Consider deploying networking infrastructure",
    var.policy_enforcement_mode == "DoNotEnforce" ? "6. Consider enabling policy enforcement mode when ready" : "6. Monitor policy compliance and exemptions"
  ]
}

# ============================================================================
# COMPUTE RESOURCE OUTPUTS (OPTIONAL)
# ============================================================================

output "vm_info" {
  description = "Virtual machine deployment information"
  value       = var.deploy_compute_resources ? module.compute.connection_info : null
  sensitive   = true
}

output "vm_resource_group_name" {
  description = "Name of the VM resource group"
  value       = var.deploy_compute_resources ? module.compute.resource_group_name : null
}

output "vm_id" {
  description = "ID of the deployed virtual machine"
  value       = var.deploy_compute_resources ? module.compute.vm_id : null
}

output "vm_public_ip" {
  description = "Public IP address of the VM"
  value       = var.deploy_compute_resources ? module.compute.vm_public_ip : null
}

output "vm_private_ip" {
  description = "Private IP address of the VM"
  value       = var.deploy_compute_resources ? module.compute.vm_private_ip : null
}

output "security_group_info" {
  description = "Security group information"
  value = var.deploy_compute_resources ? {
    name  = module.compute.network_security_group_name
    id    = module.compute.network_security_group_id
    rules = "HTTP (80), HTTPS (443), SSH (22), RDP (3389) allowed from all sources"
  } : null
}

output "vm_monitoring_info" {
  description = "Azure Monitor configuration for VM"
  value       = var.deploy_compute_resources ? module.compute.monitoring_info : null
}

output "log_analytics_workspace_id" {
  description = "Production Log Analytics Workspace ID for VM monitoring"
  value       = var.deploy_log_analytics_workspace ? module.optional_resources.log_analytics_workspace_prod_id : null
}

# Observability outputs (parameterized)
output "log_analytics_workspace_ids" {
  description = "Map of available Log Analytics workspaces by environment"
  value = var.deploy_log_analytics_workspace ? {
    prod    = module.optional_resources.log_analytics_workspace_prod_id
    nonprod = module.optional_resources.log_analytics_workspace_nonprod_id
  } : {}
}

output "selected_log_analytics_workspace_id" {
  description = "The selected Log Analytics workspace ID based on observability_environment"
  value = var.deploy_log_analytics_workspace ? (
    var.observability_environment == "prod" ? module.optional_resources.log_analytics_workspace_prod_id : module.optional_resources.log_analytics_workspace_nonprod_id
  ) : (var.log_analytics_workspace_id != "" ? var.log_analytics_workspace_id : null)
}

output "ssh_key_generated" {
  description = "Whether SSH key was generated by Terraform"
  value       = var.deploy_compute_resources ? module.compute.ssh_key_generated : null
}

output "ssh_key_info" {
  description = "SSH key configuration summary (including security warnings if applicable)"
  value       = var.deploy_compute_resources ? module.compute.ssh_key_info : null
}

output "ssh_private_key_pem" {
  description = "Private SSH key in PEM format (only available when generate_ssh_key=true). WARNING: This key is stored in Terraform state file!"
  value       = var.deploy_compute_resources ? module.compute.ssh_private_key_pem : null
  sensitive   = true
}

output "ssh_public_key_openssh" {
  description = "Public SSH key in OpenSSH format (only available when generate_ssh_key=true)"
  value       = var.deploy_compute_resources ? module.compute.ssh_public_key_openssh : null
}