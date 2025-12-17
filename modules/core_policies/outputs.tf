# modules/core_policies/outputs.tf - ALZ Core Policies Module Outputs

# ============================================================================
# POLICY ASSIGNMENT OUTPUTS
# ============================================================================

output "platform_policy_assignment_ids" {
  description = "Map of platform-level policy assignment names to their IDs"
  value = var.deploy_core_policies ? {
    for k, v in azurerm_management_group_policy_assignment.platform_core_policies : k => v.id
  } : {}
}

output "landing_zones_policy_assignment_ids" {
  description = "Map of landing zones policy assignment names to their IDs"
  value = var.deploy_core_policies ? {
    for k, v in azurerm_management_group_policy_assignment.landing_zones_core_policies : k => v.id
  } : {}
}

# ============================================================================
# POLICY INITIATIVE OUTPUTS
# ============================================================================

output "core_security_initiative_id" {
  description = "ID of the core security policy initiative"
  value       = var.deploy_core_policies && var.create_policy_initiative ? azurerm_policy_set_definition.core_security[0].id : null
}

output "core_security_initiative_assignment_id" {
  description = "ID of the core security policy initiative assignment"
  value       = var.deploy_core_policies && var.create_policy_initiative ? azurerm_management_group_policy_assignment.core_security_initiative[0].id : null
}

# ============================================================================
# POLICY EXEMPTION OUTPUTS
# ============================================================================

output "sandbox_exemption_ids" {
  description = "Map of sandbox policy exemption names to their IDs"
  value = var.create_sandbox_exemptions ? {
    for k, v in azurerm_management_group_policy_exemption.sandbox_exemptions : k => v.id
  } : {}
}

# ============================================================================
# POLICY SUMMARY OUTPUTS
# ============================================================================

output "deployed_policies_summary" {
  description = "Summary of deployed policies"
  value = var.deploy_core_policies ? {
    platform_policies_count      = length(azurerm_management_group_policy_assignment.platform_core_policies)
    landing_zones_policies_count = length(azurerm_management_group_policy_assignment.landing_zones_core_policies)
    initiative_created           = var.create_policy_initiative
    sandbox_exemptions_created   = var.create_sandbox_exemptions
    enforcement_mode             = var.policy_enforcement_mode
  } : null
}

# ============================================================================
# DINE OUTPUTS
# ============================================================================

output "dine_policy_assignment_ids" {
  description = "IDs of DINE policy assignments (Activity Logs, Bastion, NSG)"
  value = var.deploy_diagnostic_policies && length(var.log_analytics_workspace_id) > 0 ? {
    activity_logs = one(azurerm_management_group_policy_assignment.dine_activity_logs[*].id)
    bastion       = one(azurerm_management_group_policy_assignment.dine_bastion[*].id)
    nsg           = one(azurerm_management_group_policy_assignment.dine_nsg[*].id)
  } : null
}