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

resource "tls_private_key" "vm_key" {
  count     = var.generate_ssh_key ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_prefix}-${var.env}-webmysql-${var.location}-rg"
  location = var.location
  tags     = var.tags
}

# VNet and Subnet (optional)
resource "azurerm_virtual_network" "vnet" {
  count               = var.create_vnet ? 1 : 0
  name                = "${var.resource_prefix}-${var.env}-webmysql-${var.location}-vnet"
  address_space       = ["10.11.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_subnet" "subnet" {
  count                = var.create_vnet ? 1 : 0
  name                 = "${var.resource_prefix}-${var.env}-webmysql-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet[0].name
  address_prefixes     = ["10.11.1.0/24"]
}

# NSGs
resource "azurerm_network_security_group" "web_nsg" {
  name                = "${var.resource_prefix}-${var.env}-web-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

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

  security_rule {
    name                       = "DenySSHInternet"
    priority                   = 121
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSHFromBastion"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.bastion_source_cidr
    destination_address_prefix = "*"
  }

  # Allow Azure platform IP used by Bastion/health probe
  security_rule {
    name                       = "AllowSSHFromAzure168"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "168.63.129.16"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "mysql_nsg" {
  name                = "${var.resource_prefix}-${var.env}-mysql-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  security_rule {
    name                       = "AllowMySQLFromVNet"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Allow SSH from Bastion subnet
  security_rule {
    name                       = "AllowSSHFromBastion"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.bastion_source_cidr
    destination_address_prefix = "*"
  }

  # Allow Azure platform IP used by Bastion/health probe
  security_rule {
    name                       = "AllowSSHFromAzure168"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "168.63.129.16"
    destination_address_prefix = "*"
  }

  # Deny SSH from Internet fallback
  security_rule {
    name                       = "DenySSHInternet"
    priority                   = 121
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

# Public IP for Web (optional)
resource "azurerm_public_ip" "web_pip" {
  count               = var.assign_public_ip ? 1 : 0
  name                = "${var.resource_prefix}-${var.env}-web-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# NICs
resource "azurerm_network_interface" "web_nic" {
  name                = "${var.resource_prefix}-${var.env}-web-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "ipcfg"
    subnet_id                     = var.create_vnet ? azurerm_subnet.subnet[0].id : var.existing_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.assign_public_ip ? azurerm_public_ip.web_pip[0].id : null
  }
}

resource "azurerm_network_interface" "mysql_nic" {
  name                = "${var.resource_prefix}-${var.env}-mysql-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "ipcfg"
    subnet_id                     = var.create_vnet ? azurerm_subnet.subnet[0].id : var.existing_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# NSG associations
resource "azurerm_network_interface_security_group_association" "web_nic_nsg" {
  network_interface_id      = azurerm_network_interface.web_nic.id
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}

resource "azurerm_network_interface_security_group_association" "mysql_nic_nsg" {
  network_interface_id      = azurerm_network_interface.mysql_nic.id
  network_security_group_id = azurerm_network_security_group.mysql_nsg.id
}

locals {
  mysql_private_ip = azurerm_network_interface.mysql_nic.ip_configuration[0].private_ip_address
}

# Cloud-init scripts
locals {
  web_cloud_init = <<-EOT
    #cloud-config
    packages:
      - python3
      - python3-pip
    runcmd:
      - pip3 install flask mysql-connector-python
      - mkdir -p /opt/app
      - bash -lc "cat > /opt/app/app.py << 'PY'
from flask import Flask, request
import mysql.connector

app = Flask(__name__)

def get_conn():
    return mysql.connector.connect(
        host='${local.mysql_private_ip}',
        user='${var.db_username}',
        password='${var.db_password}',
        database='${var.db_name}'
    )

@app.route('/')
def index():
    return 'Web app OK. Try /items to query DB.'

@app.route('/items')
def items():
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("CREATE TABLE IF NOT EXISTS items(id INT PRIMARY KEY AUTO_INCREMENT, name VARCHAR(100))")
        cur.execute("INSERT INTO items(name) VALUES('hello')")
        conn.commit()
        cur.execute("SELECT id, name FROM items ORDER BY id DESC LIMIT 5")
        rows = cur.fetchall()
        return {'items':[{'id':r[0],'name':r[1]} for r in rows]}
    except Exception as e:
        return {'error': str(e)}
  finally:
    try:
      cur.close()
      conn.close()
    except Exception:
      pass

if __name__ == '__main__':
  app.run(host='0.0.0.0', port=80)
PY"
      - bash -lc "cat > /etc/systemd/system/app.service << 'UNIT'
[Unit]
Description=Flask App
After=network.target

[Service]
User=root
WorkingDirectory=/opt/app
ExecStart=/usr/bin/python3 /opt/app/app.py
Restart=always

[Install]
WantedBy=multi-user.target
UNIT"
      - systemctl daemon-reload
      - systemctl enable --now app.service
  EOT

  mysql_cloud_init = <<-EOT
    #cloud-config
    packages:
      - mysql-server
    runcmd:
      - sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf || true
      - systemctl restart mysql
      - mysql -uroot -e "CREATE DATABASE IF NOT EXISTS ${var.db_name};"
      - mysql -uroot -e "CREATE USER IF NOT EXISTS '${var.db_username}'@'%' IDENTIFIED BY '${var.db_password}';"
      - mysql -uroot -e "GRANT ALL PRIVILEGES ON ${var.db_name}.* TO '${var.db_username}'@'%'; FLUSH PRIVILEGES;"
  EOT
}

  # Content for web app and systemd unit, written via VM extension
  locals {
    web_app_py = <<-PY
    from flask import Flask
    import mysql.connector

    app = Flask(__name__)

    def get_conn():
      return mysql.connector.connect(
        host='${local.mysql_private_ip}',
        user='${var.db_username}',
        password='${var.db_password}',
        database='${var.db_name}'
      )

    @app.get('/')
    def index():
      return 'Web app OK. Try /items to query DB.'

    @app.get('/items')
    def items():
      conn = None
      cur = None
      try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("CREATE TABLE IF NOT EXISTS items(id INT PRIMARY KEY AUTO_INCREMENT, name VARCHAR(100))")
        cur.execute("INSERT INTO items(name) VALUES('hello')")
        conn.commit()
        cur.execute("SELECT id, name FROM items ORDER BY id DESC LIMIT 5")
        rows = cur.fetchall()
        return {'items': [{'id': r[0], 'name': r[1]} for r in rows]}
      except Exception as e:
        return {'error': str(e)}
      finally:
        if cur is not None:
          try:
            cur.close()
          except Exception:
            pass
        if conn is not None:
          try:
            conn.close()
          except Exception:
            pass

    if __name__ == '__main__':
      app.run(host='0.0.0.0', port=80)
    PY

    web_service_unit = <<-UNIT
    [Unit]
    Description=Flask App
    After=network-online.target
    Wants=network-online.target

    [Service]
    Type=simple
    User=root
    WorkingDirectory=/opt/app
    ExecStart=/usr/bin/python3 /opt/app/app.py
    Restart=always

    [Install]
    WantedBy=multi-user.target
    UNIT

    web_app_py_b64         = base64encode(local.web_app_py)
    web_service_unit_b64   = base64encode(local.web_service_unit)
  }

# Web VM
resource "azurerm_linux_virtual_machine" "web" {
  name                = "${var.resource_prefix}-${var.env}-web"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = var.admin_username
  disable_password_authentication = true

  identity {
    type = "SystemAssigned"
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.generate_ssh_key ? tls_private_key.vm_key[0].public_key_openssh : file(var.ssh_public_key_path)
  }

  network_interface_ids = [azurerm_network_interface.web_nic.id]

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

  custom_data = base64encode(local.web_cloud_init)
}

# Ensure web app is provisioned and started via Custom Script Extension (idempotent)
resource "azurerm_virtual_machine_extension" "web_init" {
  name                 = "init-web-app"
  virtual_machine_id   = azurerm_linux_virtual_machine.web.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  protected_settings = jsonencode({
    commandToExecute = join(" && ", [
      "set -eux",
      "sudo apt-get update -y",
      "sudo apt-get install -y python3 python3-pip",
      "sudo pip3 install --upgrade pip flask mysql-connector-python",
      "sudo mkdir -p /opt/app",
      "sudo bash -lc \"printf '%s' '${local.web_app_py_b64}' | base64 -d | tee /opt/app/app.py >/dev/null\"",
      "sudo bash -lc \"printf '%s' '${local.web_service_unit_b64}' | base64 -d | tee /etc/systemd/system/app.service >/dev/null\"",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable --now app.service",
      "sudo systemctl status app --no-pager --full || true"
    ])
  })
}

# MySQL VM
resource "azurerm_linux_virtual_machine" "mysql" {
  name                = "${var.resource_prefix}-${var.env}-mysql"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = var.admin_username
  disable_password_authentication = true

  identity {
    type = "SystemAssigned"
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.generate_ssh_key ? tls_private_key.vm_key[0].public_key_openssh : file(var.ssh_public_key_path)
  }

  network_interface_ids = [azurerm_network_interface.mysql_nic.id]

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

  custom_data = base64encode(local.mysql_cloud_init)
}

# Enable Azure AD Login on both VMs
resource "azurerm_virtual_machine_extension" "web_aad_login" {
  count               = var.enable_aad_login ? 1 : 0
  name                 = "AADLoginForLinux"
  virtual_machine_id   = azurerm_linux_virtual_machine.web.id
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADSSHLoginForLinux"
  type_handler_version = "1.0"
  tags = merge(var.tags, { AADForce = "2025-12-18-1" })
}

resource "azurerm_virtual_machine_extension" "mysql_aad_login" {
  count               = var.enable_aad_login ? 1 : 0
  name                 = "AADLoginForLinux"
  virtual_machine_id   = azurerm_linux_virtual_machine.mysql.id
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADSSHLoginForLinux"
  type_handler_version = "1.0"
  tags = merge(var.tags, { AADForce = "2025-12-18-1" })
}
