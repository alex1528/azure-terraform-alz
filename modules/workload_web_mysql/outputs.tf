output "web_private_ip" {
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
