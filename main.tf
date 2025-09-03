# Define the required provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Configure the Azure provider
provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "sec" {
  name     = var.azurerm_resource_group_name  # Corrected variable name
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "net" {
  name                = "${var.project_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.sec.location
  resource_group_name = azurerm_resource_group.sec.name
}

# Subnet
resource "azurerm_subnet" "web-tier" {
  name                 = "web-tier-subnet"
  resource_group_name  = azurerm_resource_group.sec.name
  virtual_network_name = azurerm_virtual_network.net.name  # Corrected reference from 'sec' to 'net'
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Interface
resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = azurerm_resource_group.sec.location
  resource_group_name = azurerm_resource_group.sec.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web-tier.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "secure" {
  name                = "security-machine"
  resource_group_name = azurerm_resource_group.sec.name
  location            = azurerm_resource_group.sec.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

 admin_password = var.admin_password   # <-- Add a strong password here
  disable_password_authentication = false     # <-- Important when using passwords

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# Network Security Group
resource "azurerm_network_security_group" "web_tier" {
  name                = "${var.project_name}-web-tier-nsg"
  location            = azurerm_resource_group.sec.location
  resource_group_name = azurerm_resource_group.sec.name  # Use consistent reference

  # Allow HTTP traffic
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow HTTPS traffic
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow SSH from management subnet only
  security_rule {
    name                       = "AllowSSHFromManagement"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.4.0/24"
    destination_address_prefix = "*"
  }

  # Deny all other inbound traffic
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Optional: Associate NSG with Subnet
resource "azurerm_subnet_network_security_group_association" "web_tier" {
  subnet_id                 = azurerm_subnet.web-tier.id
  network_security_group_id = azurerm_network_security_group.web_tier.id
}