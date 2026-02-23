resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.prefix}-${random_string.suffix.result}"
  location = var.location
  tags     = local.common_tags
}

module "network" {
  source = "./modules/network"

  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  prefix                   = var.prefix
  suffix                   = random_string.suffix.result
  tags                     = local.common_tags
  allowed_jump_source_ips  = var.allowed_jump_source_ips
  core_vnet_cidr           = var.core_vnet_cidr
  jump_vnet_cidr           = var.jump_vnet_cidr
}

module "platform" {
  source = "./modules/platform"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  prefix              = var.prefix
  suffix              = random_string.suffix.result
  tags                = local.common_tags

  tenant_id                   = var.tenant_id
  subscription_id             = var.subscription_id
  admin_username              = var.admin_username
  admin_password              = var.admin_password
  postgres_admin_login        = var.postgres_admin_login
  postgres_admin_password     = var.postgres_admin_password
  ssh_public_key              = var.ssh_public_key
  function_package_url        = var.function_package_url
  filesync_registered_server_id = var.filesync_registered_server_id

  current_object_id         = data.azurerm_client_config.current.object_id
  entra_object_id           = data.azuread_client_config.current.object_id
  entra_display_name        = data.azuread_client_config.current.display_name

  subnet_jump_id            = module.network.subnet_jump_id
  subnet_appgw_id           = module.network.subnet_appgw_id
  subnet_aks_id             = module.network.subnet_aks_id
  subnet_function_id        = module.network.subnet_function_id
  subnet_db_id              = module.network.subnet_db_id
  subnet_private_endpoints_id = module.network.subnet_private_endpoints_id
  core_vnet_id              = module.network.core_vnet_id

  jump_public_ip_id         = module.network.jump_public_ip_id
  appgw_public_ip_id        = module.network.appgw_public_ip_id
}

module "governance" {
  source = "./modules/governance"

  subscription_id = var.subscription_id
}

data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}
