resource "azurerm_virtual_network" "core" {
  name                = "vnet-core-${var.prefix}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.core_vnet_cidr]
  tags                = var.tags
}

resource "azurerm_virtual_network" "jump" {
  name                = "vnet-jump-${var.prefix}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.jump_vnet_cidr]
  tags                = var.tags
}

resource "azurerm_virtual_network_peering" "jump_to_core" {
  name                      = "jump-to-core"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.jump.name
  remote_virtual_network_id = azurerm_virtual_network.core.id
}

resource "azurerm_virtual_network_peering" "core_to_jump" {
  name                      = "core-to-jump"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.core.name
  remote_virtual_network_id = azurerm_virtual_network.jump.id
}

resource "azurerm_subnet" "jump" {
  name                 = "snet-jump"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.jump.name
  address_prefixes     = ["10.50.1.0/24"]
}

resource "azurerm_subnet" "appgw" {
  name                 = "snet-appgw"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.core.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.core.name
  address_prefixes     = ["10.10.2.0/23"]
}

resource "azurerm_subnet" "function" {
  name                 = "snet-function"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.core.name
  address_prefixes     = ["10.10.4.0/24"]

  delegation {
    name = "delegation-appservice"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "db" {
  name                 = "snet-db"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.core.name
  address_prefixes     = ["10.10.5.0/24"]

  delegation {
    name = "delegation-postgresql"

    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-private-endpoints"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.core.name
  address_prefixes     = ["10.10.6.0/24"]
}

resource "azurerm_network_security_group" "jump" {
  name                = "nsg-jump-${var.prefix}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "AllowRDPFromAllowedIPs"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefixes    = var.allowed_jump_source_ips
    destination_address_prefix = "*"
  }

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

resource "azurerm_subnet_network_security_group_association" "jump" {
  subnet_id                 = azurerm_subnet.jump.id
  network_security_group_id = azurerm_network_security_group.jump.id
}

resource "azurerm_public_ip" "jump" {
  name                = "pip-jump-${var.prefix}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_public_ip" "appgw" {
  name                = "pip-appgw-${var.prefix}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}
