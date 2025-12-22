output "resource_group_name" {
  description = "Name of the optional resources resource group"
  value       = azurerm_resource_group.optional_resources.name
}

output "resource_group_id" {
  description = "ID of the optional resources resource group"
  value       = azurerm_resource_group.optional_resources.id
} # outputs.tf in optional_resources module

output "management_resource_group_name" {
  value       = azurerm_resource_group.optional_resources.name
  description = "Name of the resource group created for optional resources"
}

output "log_analytics_workspace_prod_id" {
  value       = var.deploy_log_analytics_workspace ? azurerm_log_analytics_workspace.prod[0].id : ""
  description = "Resource ID of the production Log Analytics Workspace"
}

output "log_analytics_workspace_nonprod_id" {
  value       = var.deploy_log_analytics_workspace ? azurerm_log_analytics_workspace.nonprod[0].id : ""
  description = "Resource ID of the non-production Log Analytics Workspace"
}

output "defender_for_cloud_summary" {
  value = {
    enabled            = var.enable_defender_for_cloud
    tier               = local.effective_defender_tier
    auto_provision     = var.defender_auto_provision
    plans              = var.enable_defender_for_cloud ? sort(tolist(local.effective_defender_plans)) : []
    workspace_linked   = var.enable_defender_for_cloud && var.deploy_log_analytics_workspace
    workspace_selected = var.deploy_log_analytics_workspace ? (var.observability_environment == "prod" ? azurerm_log_analytics_workspace.prod[0].id : azurerm_log_analytics_workspace.nonprod[0].id) : ""
  }
  description = "Summary of Defender for Cloud configuration"
}
