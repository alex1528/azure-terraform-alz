output "resource_group_id" {
  description = "ID of the workload resource group"
  value       = azurerm_resource_group.rg.id
}

output "vnet_id" {
  description = "ID of the workload VNet (when created)"
  value       = var.create_vnet ? azurerm_virtual_network.vnet[0].id : null
}

output "subnet_id" {
  description = "ID of the workload subnet (when created)"
  value       = var.create_vnet ? azurerm_subnet.subnet[0].id : var.existing_subnet_id
}output "web_private_ip" {
  description = "Web VM private IP"
  value       = azurerm_network_interface.web_nic.ip_configuration[0].private_ip_address
}

output "mysql_private_ip" {
  description = "MySQL VM private IP"
  value       = azurerm_network_interface.mysql_nic.ip_configuration[0].private_ip_address
}

output "web_public_ip" {
  description = "Web public IP (if assigned)"
  value       = try(azurerm_public_ip.web_pip[0].ip_address, null)
}

output "resource_group_id" {
  description = "Resource group ID for the workload"
  value       = azurerm_resource_group.rg.id
}

output "resource_group_name" {
  description = "Resource group name for the workload"
  value       = azurerm_resource_group.rg.name
}

output "web_vm_id" {
  description = "Web VM resource ID"
  value       = azurerm_linux_virtual_machine.web.id
}

output "mysql_vm_id" {
  description = "MySQL VM resource ID"
  value       = azurerm_linux_virtual_machine.mysql.id
}
