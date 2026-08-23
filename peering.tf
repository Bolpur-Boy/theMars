# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "Finland"
  location = "westus"
  
  tags = {
    Environment = "Terraform Getting Started"
    Team = "DevOps"
  }
}
# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "HO"
  address_space       = ["172.16.0.0/16"]
  location            = "westus"
  resource_group_name = azurerm_resource_group.rg.name

}
# Create subnet for worksSN
resource "azurerm_subnet" "it" {
  name                 = "it"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["172.16.1.0/24"]
}

# Create subnet for AppSN
resource "azurerm_subnet" "accts" {
  name                 = "accts"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["172.16.2.0/24"]
}
# Create a virtual network
resource "azurerm_virtual_network" "vnet1" {
  name                = "Junglepur"
  address_space       = ["172.25.0.0/16"]
  location            = "westus"
  resource_group_name = azurerm_resource_group.rg.name

}
# Create subnet for works
resource "azurerm_subnet" "it1" {
  name                 = "it"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["172.25.1.0/24"]
}
