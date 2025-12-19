# modules/connectivity/main.tf - ALZ Connectivity Module

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  }
}

# ============================================================================
# CONNECTIVITY RESOURCE GROUP
# ============================================================================

resource "azurerm_resource_group" "connectivity" {
  name     = var.connectivity_rg_name
  location = var.location
  tags     = var.tags
}

# ============================================================================
# HUB & SPOKE ARCHITECTURE RESOURCES
# ============================================================================

# Hub Virtual Network
resource "azurerm_virtual_network" "hub" {
  count               = var.deploy_hub_spoke ? 1 : 0
  name                = var.hub_vnet_name
  address_space       = var.hub_vnet_address_space
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name
  tags                = var.tags
}

# Hub Subnets
resource "azurerm_subnet" "hub_subnets" {
  for_each             = var.deploy_hub_spoke ? var.hub_subnets : {}
  name                 = each.key
  resource_group_name  = azurerm_resource_group.connectivity.name
  virtual_network_name = azurerm_virtual_network.hub[0].name
  address_prefixes     = each.value.address_prefixes

  # Service delegations if specified
  dynamic "delegation" {
    for_each = each.value.delegations
    content {
      name = delegation.value
      service_delegation {
        name = delegation.value
      }
    }
  }
}

# Network Security Group for Hub Subnets (excluding special Azure subnets)
resource "azurerm_network_security_group" "hub_subnets" {
  for_each = var.deploy_hub_spoke ? {
    for subnet_name, subnet_config in var.hub_subnets :
    subnet_name => subnet_config
    if !startswith(subnet_name, "Azure") # Exclude Azure special subnets
  } : {}

  name                = "${each.key}-nsg"
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name
  tags                = var.tags

  # Default deny-all inbound rule (can be overridden with more specific rules)
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSGs with Hub Subnets
resource "azurerm_subnet_network_security_group_association" "hub_subnets" {
  for_each = var.deploy_hub_spoke ? {
    for subnet_name, subnet_config in var.hub_subnets :
    subnet_name => subnet_config
    if !startswith(subnet_name, "Azure") # Exclude Azure special subnets
  } : {}

  subnet_id                 = azurerm_subnet.hub_subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.hub_subnets[each.key].id
}

# ============================================================================
# VIRTUAL WAN ARCHITECTURE RESOURCES
# ============================================================================

# Virtual WAN
resource "azurerm_virtual_wan" "main" {
  count                          = var.deploy_vwan ? 1 : 0
  name                           = var.virtual_wan_name
  resource_group_name            = azurerm_resource_group.connectivity.name
  location                       = azurerm_resource_group.connectivity.location
  disable_vpn_encryption         = false
  allow_branch_to_branch_traffic = true
  type                           = "Standard"
  tags                           = var.tags
}

# Virtual Hub
resource "azurerm_virtual_hub" "main" {
  count               = var.deploy_vwan ? 1 : 0
  name                = var.virtual_hub_name
  resource_group_name = azurerm_resource_group.connectivity.name
  location            = azurerm_resource_group.connectivity.location
  virtual_wan_id      = azurerm_virtual_wan.main[0].id
  address_prefix      = var.virtual_hub_address_prefix
  tags                = var.tags
}

# ExpressRoute Gateway (Optional)
resource "azurerm_express_route_gateway" "main" {
  count               = var.deploy_vwan && var.deploy_express_route_gateway ? 1 : 0
  name                = var.express_route_gateway_name
  resource_group_name = azurerm_resource_group.connectivity.name
  location            = azurerm_resource_group.connectivity.location
  virtual_hub_id      = azurerm_virtual_hub.main[0].id
  scale_units         = 1
  tags                = var.tags
}

# VPN Gateway (Optional)
resource "azurerm_vpn_gateway" "main" {
  count               = var.deploy_vwan && var.deploy_vpn_gateway ? 1 : 0
  name                = var.vpn_gateway_name
  resource_group_name = azurerm_resource_group.connectivity.name
  location            = azurerm_resource_group.connectivity.location
  virtual_hub_id      = azurerm_virtual_hub.main[0].id
  tags                = var.tags
}

# ============================================================================
# AZURE FIREWALL (Optional - can be deployed in either architecture)
# ============================================================================

# Public IP for Azure Firewall (Hub & Spoke only)
resource "azurerm_public_ip" "firewall" {
  count               = var.deploy_hub_spoke && var.deploy_azure_firewall ? 1 : 0
  name                = "${var.hub_vnet_name}-fw-pip"
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Azure Firewall (Hub & Spoke)
resource "azurerm_firewall" "hub" {
  count               = var.deploy_hub_spoke && var.deploy_azure_firewall ? 1 : 0
  name                = "${var.hub_vnet_name}-fw"
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.hub_subnets["AzureFirewallSubnet"].id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }
}

# Azure Firewall (Virtual WAN)
resource "azurerm_firewall" "vwan" {
  count               = var.deploy_vwan && var.deploy_azure_firewall ? 1 : 0
  name                = "${var.virtual_hub_name}-fw"
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name
  sku_name            = "AZFW_Hub"
  sku_tier            = "Standard"
  tags                = var.tags

  virtual_hub {
    virtual_hub_id  = azurerm_virtual_hub.main[0].id
    public_ip_count = 1
  }
}

# ============================================================================
# AZURE BASTION (Optional for Hub & Spoke)
# ============================================================================

# Public IP for Azure Bastion
resource "azurerm_public_ip" "bastion" {
  count               = var.deploy_hub_spoke && var.deploy_azure_bastion ? 1 : 0
  name                = "${var.hub_vnet_name}-bastion-pip"
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Azure Bastion Host
resource "azurerm_bastion_host" "main" {
  count               = var.deploy_hub_spoke && var.deploy_azure_bastion ? 1 : 0
  name                = "${var.hub_vnet_name}-bastion"
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name
  sku                 = "Standard"
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.hub_subnets["AzureBastionSubnet"].id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }
}

# ============================================================================
# ROUTE TABLES AND ROUTING (Hub & Spoke)
# ============================================================================

# Route table for spoke networks (forces traffic through hub)
resource "azurerm_route_table" "spoke_routes" {
  count               = var.deploy_hub_spoke ? 1 : 0
  name                = "${var.hub_vnet_name}-spoke-rt"
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name
  tags                = var.tags

  # Default route through Azure Firewall (if deployed)
  dynamic "route" {
    for_each = var.deploy_azure_firewall ? [1] : []
    content {
      name                   = "default-via-firewall"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = azurerm_firewall.hub[0].ip_configuration[0].private_ip_address
    }
  }
}