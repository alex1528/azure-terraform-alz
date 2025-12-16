# modules/compute/main.tf - Azure VM and Compute Resources

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# ============================================================================
# SSH KEY GENERATION (Optional - when generate_ssh_key = true)
# ============================================================================

resource "tls_private_key" "vm_key" {
  count     = var.generate_ssh_key ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# ============================================================================
# RESOURCE GROUP FOR COMPUTE
# ============================================================================

resource "azurerm_resource_group" "compute" {
  count    = var.deploy_compute_resources ? 1 : 0
  name     = "${var.resource_prefix}-compute-${var.location}-rg"
  location = var.location
  tags     = var.tags
}

# ============================================================================
# SECURITY GROUP - ALLOW HTTP/HTTPS
# ============================================================================

resource "azurerm_network_security_group" "vm_nsg" {
  count               = var.deploy_compute_resources ? 1 : 0
  name                = "${var.resource_prefix}-vm-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.compute[0].name
  tags                = var.tags

  # Deny all inbound by default
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

  # Allow HTTP (port 80)
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow HTTPS (port 443)
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Deny SSH (port 22) from internet as per network security policy
  security_rule {
    name                       = "DenySSHInternet"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow SSH (port 22) - from Bastion subnet only for secure management
  security_rule {
    name                       = "AllowSSHFromBastion"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.2.0/26"  # AzureBastionSubnet
    destination_address_prefix = "*"
  }

  # Deny RDP (port 3389) from internet as per network security policy
  security_rule {
    name                       = "DenyRDPInternet"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow RDP (port 3389) - from Bastion subnet only for secure management
  security_rule {
    name                       = "AllowRDPFromBastion"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "10.0.2.0/26"  # AzureBastionSubnet
    destination_address_prefix = "*"
  }

  # Allow all outbound by default
  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ============================================================================
# VIRTUAL NETWORK FOR VMS (or use existing from connectivity module)
# ============================================================================

resource "azurerm_virtual_network" "compute_vnet" {
  count               = var.deploy_compute_resources && var.create_compute_vnet ? 1 : 0
  name                = "${var.resource_prefix}-compute-${var.location}-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.compute[0].name
  tags                = var.tags
}

resource "azurerm_subnet" "compute_subnet" {
  count                = var.deploy_compute_resources && var.create_compute_vnet ? 1 : 0
  name                 = "${var.resource_prefix}-compute-subnet"
  resource_group_name  = azurerm_resource_group.compute[0].name
  virtual_network_name = azurerm_virtual_network.compute_vnet[0].name
  address_prefixes     = ["10.1.1.0/24"]
}

# ============================================================================
# NETWORK INTERFACE FOR VM
# ============================================================================

resource "azurerm_network_interface" "vm_nic" {
  count               = var.deploy_compute_resources ? 1 : 0
  name                = "${var.resource_prefix}-vm-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.compute[0].name
  tags                = var.tags

  ip_configuration {
    name                          = "testConfiguration"
    subnet_id                     = var.create_compute_vnet ? azurerm_subnet.compute_subnet[0].id : var.existing_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.assign_public_ip ? azurerm_public_ip.vm_public_ip[0].id : null
  }
}

# Attach NSG to NIC
resource "azurerm_network_interface_security_group_association" "vm_nic_nsg" {
  count                     = var.deploy_compute_resources ? 1 : 0
  network_interface_id      = azurerm_network_interface.vm_nic[0].id
  network_security_group_id = azurerm_network_security_group.vm_nsg[0].id
}

# ============================================================================
# PUBLIC IP ADDRESS (OPTIONAL)
# ============================================================================

resource "azurerm_public_ip" "vm_public_ip" {
  count               = var.deploy_compute_resources && var.assign_public_ip ? 1 : 0
  name                = "${var.resource_prefix}-vm-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.compute[0].name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# ============================================================================
# VIRTUAL MACHINE (LINUX - Ubuntu)
# ============================================================================

resource "azurerm_linux_virtual_machine" "vm" {
  count               = var.deploy_compute_resources && var.vm_os_type == "linux" ? 1 : 0
  name                = "${var.resource_prefix}-vm"
  location            = var.location
  resource_group_name = azurerm_resource_group.compute[0].name
  tags                = var.tags

  # Size: 4 vCPUs, 8GB RAM = Standard_B2s or Standard_D2s_v3
  size = var.vm_size

  admin_username = var.admin_username

  # Disable SSH password authentication
  disable_password_authentication = true

  # SSH key authentication
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.generate_ssh_key ? tls_private_key.vm_key[0].public_key_openssh : file(var.ssh_public_key_path)
  }

  # Managed identity for Azure Monitor Agent
  dynamic "identity" {
    for_each = var.enable_azure_monitor ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [azurerm_user_assigned_identity.vm_monitor_identity[0].id]
    }
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  network_interface_ids = [
    azurerm_network_interface.vm_nic[0].id,
  ]
}

# ============================================================================
# VIRTUAL MACHINE (WINDOWS)
# ============================================================================

resource "azurerm_windows_virtual_machine" "vm_windows" {
  count               = var.deploy_compute_resources && var.vm_os_type == "windows" ? 1 : 0
  name                = "${var.resource_prefix}-vm"
  location            = var.location
  resource_group_name = azurerm_resource_group.compute[0].name
  tags                = var.tags

  # Size: 4 vCPUs, 8GB RAM = Standard_B2s or Standard_D2s_v3
  size = var.vm_size

  admin_username = var.admin_username
  admin_password = var.admin_password

  # Managed identity for Azure Monitor Agent
  dynamic "identity" {
    for_each = var.enable_azure_monitor ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [azurerm_user_assigned_identity.vm_monitor_identity[0].id]
    }
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  network_interface_ids = [
    azurerm_network_interface.vm_nic[0].id,
  ]
}

# ============================================================================
# AZURE MONITOR - DIAGNOSTIC SETTINGS & AGENT
# ============================================================================

# Enable Azure Monitor Agent on Linux VM
resource "azurerm_virtual_machine_extension" "ama_agent" {
  count                      = var.deploy_compute_resources && var.vm_os_type == "linux" && var.enable_azure_monitor ? 1 : 0
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.vm[0].id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}

# Enable Azure Monitor Agent on Windows VM
resource "azurerm_virtual_machine_extension" "ama_agent_windows" {
  count                      = var.deploy_compute_resources && var.vm_os_type == "windows" && var.enable_azure_monitor ? 1 : 0
  name                       = "AzureMonitorWindowsAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm_windows[0].id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}

# User-assigned managed identity for Azure Monitor Agent
resource "azurerm_user_assigned_identity" "vm_monitor_identity" {
  count               = var.deploy_compute_resources && var.enable_azure_monitor ? 1 : 0
  resource_group_name = azurerm_resource_group.compute[0].name
  location            = var.location
  name                = "${var.resource_prefix}-vm-monitor-identity"
  tags                = var.tags
}

# Role assignment - Monitor Metrics Publisher for managed identity
resource "azurerm_role_assignment" "monitor_metrics_publisher" {
  count                = var.deploy_compute_resources && var.enable_azure_monitor ? 1 : 0
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = azurerm_user_assigned_identity.vm_monitor_identity[0].principal_id
}


