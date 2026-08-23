terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# ------------------------------
# Variables
# ------------------------------
variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "West US"
}

variable "resource_group_name" {
  description = "Resource Group name"
  type        = string
  default     = "USA"
}

variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "VM SKU size"
  type        = string
  default     = "Standard_E2s_v3"
}

variable "admin_username" {
  description = "Local administrator username for the VMs"
  type        = string
  default     = "sysadmin"
}

variable "admin_password" {
  description = "Local administrator password for the VMs (must meet Azure complexity requirements)"
  type        = string
  sensitive   = true
  default     = "theMars$666666"
}

variable "windows_sku" {
  description = "Windows Server image SKU"
  type        = string
  default     = "2025-datacenter-azure-edition"
}

# ------------------------------
# Resource Group
# ------------------------------
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}


  security_rule {
    name                       = "Allow-RDP"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"   # TODO: restrict to your admin IP range in production
    destination_address_prefix = "*"
  }



# ------------------------------
# Public IPs (one per VM)
# ------------------------------
resource "azurerm_public_ip" "pip" {
  count               = var.vm_count
  name                = "pip-win-vm-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# ------------------------------
# NICs (one per VM)
# ------------------------------
resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "nic-win-vm-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip[count.index].id
  }
}

# ------------------------------
# Windows Server VMs
# ------------------------------
resource "azurerm_windows_virtual_machine" "vm" {
  count               = var.vm_count
  name                = "win-vm-${count.index + 1}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = var.windows_sku
    version   = "latest"
  }
}

# ------------------------------
# Outputs
# ------------------------------
output "vm_names" {
  description = "Names of the created VMs"
  value       = azurerm_windows_virtual_machine.vm[*].name
}

output "vm_public_ips" {
  description = "Public IP addresses of the created VMs"
  value       = azurerm_public_ip.pip[*].ip_address
}
