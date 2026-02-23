resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.prefix}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_network_interface" "jump" {
  name                = "nic-jump-${var.prefix}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_jump_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.jump_public_ip_id
  }
}

resource "azurerm_windows_virtual_machine" "jump" {
  name                = "vm-jump-${var.prefix}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = "Standard_B1s"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  tags                = var.tags

  network_interface_ids = [azurerm_network_interface.jump.id]
  patch_mode            = "AutomaticByPlatform"

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
}

resource "azurerm_monitor_data_collection_rule" "vm_logs" {
  name                = "dcr-vm-${var.prefix}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.main.id
      name                  = "la"
    }
  }

  data_flow {
    streams      = ["Microsoft-Event"]
    destinations = ["la"]
  }

  data_sources {
    windows_event_log {
      name           = "windows-security"
      streams        = ["Microsoft-Event"]
      x_path_queries = ["Security!*[System[(Level=1 or Level=2 or Level=3 or Level=4)]]"]
    }
  }
}

resource "azurerm_monitor_data_collection_rule_association" "jump" {
  name                    = "assoc-jump"
  target_resource_id      = azurerm_windows_virtual_machine.jump.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.vm_logs.id
}

resource "azurerm_user_assigned_identity" "aks_workload" {
  name                = "uami-aks-workload-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "appgw" {
  name                = "uami-appgw-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_container_registry" "main" {
  name                = "acr${var.prefix}${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  admin_enabled       = false
  tags                = var.tags
}

resource "azurerm_storage_account" "main" {
  name                             = "st${var.prefix}${var.suffix}"
  resource_group_name              = var.resource_group_name
  location                         = var.location
  account_tier                     = "Standard"
  account_replication_type         = "LRS"
  public_network_access_enabled    = false
  cross_tenant_replication_enabled = false
  shared_access_key_enabled        = true
  tags                             = var.tags
}

resource "azurerm_storage_container" "blobs" {
  name                  = "appdata"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_storage_share" "files" {
  name                 = "fileshare"
  storage_account_name = azurerm_storage_account.main.name
  quota                = 100
  enabled_protocol     = "SMB"
}

resource "azurerm_storage_sync" "main" {
  name                    = "stsync-${var.prefix}-${var.suffix}"
  resource_group_name     = var.resource_group_name
  location                = var.location
  incoming_traffic_policy = "AllowAllTraffic"
  tags                    = var.tags
}

resource "azurerm_storage_sync_group" "main" {
  name            = "sg-${var.prefix}-${var.suffix}"
  storage_sync_id = azurerm_storage_sync.main.id
}

resource "azurerm_storage_sync_cloud_endpoint" "main" {
  name                  = "cloudendpoint-files"
  storage_sync_group_id = azurerm_storage_sync_group.main.id
  file_share_name       = azurerm_storage_share.files.name
  storage_account_id    = azurerm_storage_account.main.id
}

resource "azurerm_storage_sync_server_endpoint" "jump_simulated" {
  count                 = var.filesync_registered_server_id == "" ? 0 : 1
  name                  = "serverendpoint-jump"
  storage_sync_group_id = azurerm_storage_sync_group.main.id
  registered_server_id  = var.filesync_registered_server_id
  server_local_path     = "D:\\filesync"
}

resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "pdns-postgres-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  resource_group_name   = var.resource_group_name
  virtual_network_id    = var.core_vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "pg-${var.prefix}-${var.suffix}"
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = "16"
  delegated_subnet_id    = var.subnet_db_id
  private_dns_zone_id    = azurerm_private_dns_zone.postgres.id
  administrator_login    = var.postgres_admin_login
  administrator_password = var.postgres_admin_password
  sku_name               = "B_Standard_B1ms"
  backup_retention_days  = 7
  tags                   = var.tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "entra_admin" {
  server_name         = azurerm_postgresql_flexible_server.main.name
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  object_id           = var.entra_object_id
  principal_name      = var.entra_display_name
  principal_type      = "ServicePrincipal"
}

resource "azurerm_key_vault" "main" {
  name                          = "kv-${var.prefix}-${var.suffix}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  public_network_access_enabled = false
  tags                          = var.tags
}

resource "azurerm_role_assignment" "current_user_kv_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.current_object_id
}

resource "azurerm_key_vault_secret" "postgres_password" {
  name         = "postgres-admin-password"
  value        = var.postgres_admin_password
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.current_user_kv_admin]
}

resource "azurerm_key_vault_certificate" "appgw" {
  name         = "appgw-cert"
  key_vault_id = azurerm_key_vault.main.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      subject            = "CN=appgw.local"
      validity_in_months = 12
      key_usage          = ["digitalSignature", "keyEncipherment"]
    }
  }

  depends_on = [azurerm_role_assignment.current_user_kv_admin]
}

resource "azurerm_role_assignment" "appgw_kv_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.appgw.principal_id
}

resource "azurerm_service_plan" "function" {
  name                = "asp-${var.prefix}-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "EP1"
  tags                = var.tags
}

resource "azurerm_linux_function_app" "main" {
  name                          = "func-${var.prefix}-${var.suffix}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  service_plan_id               = azurerm_service_plan.function.id
  storage_account_name          = azurerm_storage_account.main.name
  storage_account_access_key    = azurerm_storage_account.main.primary_access_key
  https_only                    = true
  public_network_access_enabled = false
  virtual_network_subnet_id     = var.subnet_function_id
  tags                          = var.tags

  site_config {
    application_stack {
      node_version = "20"
    }
    ftps_state = "Disabled"
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = var.function_package_url != "" ? var.function_package_url : "1"
    "WEBSITE_VNET_ROUTE_ALL"   = "1"
  }
}

resource "azurerm_private_endpoint" "function" {
  name                = "pep-function-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_private_endpoints_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-function"
    private_connection_resource_id = azurerm_linux_function_app.main.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "storage_blob" {
  name                = "pep-blob-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_private_endpoints_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-blob"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "storage_file" {
  name                = "pep-file-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_private_endpoints_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-file"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "keyvault" {
  name                = "pep-kv-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_private_endpoints_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-kv"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }
}

resource "azurerm_kubernetes_cluster" "main" {
  name                      = "aks-${var.prefix}-${var.suffix}"
  location                  = var.location
  resource_group_name       = var.resource_group_name
  dns_prefix                = "${var.prefix}-${var.suffix}"
  sku_tier                  = "Standard"
  private_cluster_enabled   = true
  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  tags                      = var.tags

  default_node_pool {
    name                 = "system"
    vm_size              = "Standard_B2ats_v2"
    node_count           = 1
    vnet_subnet_id       = var.subnet_aks_id
    max_pods             = 30
    auto_scaling_enabled = false
  }

  linux_profile {
    admin_username = "azureuser"
    ssh_key {
      key_data = var.ssh_public_key
    }
  }

  identity {
    type = "SystemAssigned"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  maintenance_window_auto_upgrade {
    day_of_week = "Sunday"
    start_time  = "03:00"
    utc_offset  = "+00:00"
    duration    = 4
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
  }
}

resource "azurerm_role_assignment" "aks_to_acr" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

resource "azurerm_role_assignment" "uami_blob" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_workload.principal_id
}

resource "azurerm_role_assignment" "uami_file" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage File Data SMB Share Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_workload.principal_id
}

resource "azurerm_role_assignment" "uami_keyvault" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.aks_workload.principal_id
}

resource "azurerm_application_gateway" "main" {
  name                = "agw-${var.prefix}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "ip-config"
    subnet_id = var.subnet_appgw_id
  }

  frontend_port {
    name = "https-port"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "public-frontend"
    public_ip_address_id = var.appgw_public_ip_id
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.appgw.id]
  }

  ssl_certificate {
    name                = "kv-cert"
    key_vault_secret_id = azurerm_key_vault_certificate.appgw.secret_id
  }

  backend_address_pool {
    name  = "function-backend"
    fqdns = [azurerm_linux_function_app.main.default_hostname]
  }

  backend_address_pool {
    name = "aks-backend-placeholder"
  }

  backend_http_settings {
    name                                = "function-http"
    cookie_based_affinity               = "Disabled"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 30
    pick_host_name_from_backend_address = true
  }

  backend_http_settings {
    name                  = "aks-http"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "public-frontend"
    frontend_port_name             = "https-port"
    protocol                       = "Https"
    ssl_certificate_name           = "kv-cert"
  }

  url_path_map {
    name                               = "path-map"
    default_backend_address_pool_name  = "function-backend"
    default_backend_http_settings_name = "function-http"

    path_rule {
      name                       = "function-path"
      paths                      = ["/functionap/*"]
      backend_address_pool_name  = "function-backend"
      backend_http_settings_name = "function-http"
    }

    path_rule {
      name                       = "aks-path"
      paths                      = ["/aks/*"]
      backend_address_pool_name  = "aks-backend-placeholder"
      backend_http_settings_name = "aks-http"
    }
  }

  request_routing_rule {
    name               = "path-rule"
    rule_type          = "PathBasedRouting"
    http_listener_name = "https-listener"
    url_path_map_name  = "path-map"
    priority           = 100
  }

  depends_on = [azurerm_role_assignment.appgw_kv_secrets_user]
}

resource "azurerm_monitor_diagnostic_setting" "kv" {
  name                       = "diag-kv"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  enabled_log {
    category = "AuditEvent"
  }
}

resource "azurerm_monitor_diagnostic_setting" "storage" {
  name                       = "diag-storage"
  target_resource_id         = "${azurerm_storage_account.main.id}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  enabled_log {
    category = "StorageRead"
  }
  enabled_log {
    category = "StorageWrite"
  }
  enabled_log {
    category = "StorageDelete"
  }
}

resource "azurerm_application_insights_workbook" "monitoring" {
  name                = uuid()
  resource_group_name = var.resource_group_name
  location            = var.location
  display_name        = "wb-${var.prefix}-${var.suffix}"
  source_id           = azurerm_log_analytics_workspace.main.id
  category            = "workbook"
  tags                = var.tags

  data_json = jsonencode({
    version = "Notebook/1.0"
    items = [{ type = 1, content = { json = "# Project monitoring workbook" } }]
  })
}