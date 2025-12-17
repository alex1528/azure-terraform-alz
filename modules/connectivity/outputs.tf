# modules/connectivity/outputs.tf - ALZ Connectivity Module Outputs

# ============================================================================
# RESOURCE GROUP OUTPUTS
# ============================================================================

output "connectivity_resource_group_id" {
  description = "ID of the connectivity resource group"
  value       = azurerm_resource_group.connectivity.id
}

output "connectivity_resource_group_name" {
  description = "Name of the connectivity resource group"
  value       = azurerm_resource_group.connectivity.name
}

# ============================================================================
# HUB & SPOKE OUTPUTS
# ============================================================================

output "hub_vnet_id" {
  description = "ID of the hub virtual network"
  value       = var.deploy_hub_spoke ? azurerm_virtual_network.hub[0].id : null
}

output "hub_vnet_name" {
  description = "Name of the hub virtual network"
  value       = var.deploy_hub_spoke ? azurerm_virtual_network.hub[0].name : null
}

output "hub_vnet_address_space" {
  description = "Address space of the hub virtual network"
  value       = var.deploy_hub_spoke ? azurerm_virtual_network.hub[0].address_space : null
}

output "hub_subnet_ids" {
  description = "Map of hub subnet names to their IDs"
  value       = var.deploy_hub_spoke ? { for k, v in azurerm_subnet.hub_subnets : k => v.id } : {}
}

output "hub_subnet_cidrs" {
  description = "Map of hub subnet names to their CIDR blocks"
  value       = var.deploy_hub_spoke ? { for k, v in azurerm_subnet.hub_subnets : k => v.address_prefixes[0] } : {}
}

# ============================================================================
# VIRTUAL WAN OUTPUTS
# ============================================================================

output "virtual_wan_id" {
  description = "ID of the Virtual WAN"
  value       = var.deploy_vwan ? azurerm_virtual_wan.main[0].id : null
}

output "virtual_wan_name" {
  description = "Name of the Virtual WAN"
  value       = var.deploy_vwan ? azurerm_virtual_wan.main[0].name : null
}

output "virtual_hub_id" {
  description = "ID of the Virtual Hub"
  value       = var.deploy_vwan ? azurerm_virtual_hub.main[0].id : null
}

output "virtual_hub_name" {
  description = "Name of the Virtual Hub"
  value       = var.deploy_vwan ? azurerm_virtual_hub.main[0].name : null
}

output "virtual_hub_address_prefix" {
  description = "Address prefix of the Virtual Hub"
  value       = var.deploy_vwan ? azurerm_virtual_hub.main[0].address_prefix : null
}

# ============================================================================
# GATEWAY OUTPUTS
# ============================================================================

output "express_route_gateway_id" {
  description = "ID of the ExpressRoute gateway"
  value       = var.deploy_vwan && var.deploy_express_route_gateway ? azurerm_express_route_gateway.main[0].id : null
}

output "vpn_gateway_id" {
  description = "ID of the VPN gateway"
  value       = var.deploy_vwan && var.deploy_vpn_gateway ? azurerm_vpn_gateway.main[0].id : null
}

# ============================================================================
# FIREWALL OUTPUTS
# ============================================================================

output "azure_firewall_id" {
  description = "ID of the Azure Firewall"
  value       = var.deploy_azure_firewall ? (var.deploy_hub_spoke ? azurerm_firewall.hub[0].id : azurerm_firewall.vwan[0].id) : null
}

output "azure_firewall_private_ip" {
  description = "Private IP address of the Azure Firewall"
  value       = var.deploy_azure_firewall && var.deploy_hub_spoke ? azurerm_firewall.hub[0].ip_configuration[0].private_ip_address : null
}

# ============================================================================
# BASTION OUTPUTS
# ============================================================================

output "bastion_host_id" {
  description = "ID of the Azure Bastion host"
  value       = var.deploy_hub_spoke && var.deploy_azure_bastion ? azurerm_bastion_host.main[0].id : null
}

output "bastion_host_fqdn" {
  description = "FQDN of the Azure Bastion host"
  value       = var.deploy_hub_spoke && var.deploy_azure_bastion ? azurerm_bastion_host.main[0].dns_name : null
}


# ============================================================================
# ROUTING OUTPUTS
# ============================================================================

output "spoke_route_table_id" {
  description = "ID of the route table for spoke networks"
  value       = var.deploy_hub_spoke ? azurerm_route_table.spoke_routes[0].id : null
}