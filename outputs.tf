output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "jump_public_ip" {
  value = azurerm_public_ip.jump.ip_address
}

output "application_gateway_public_ip" {
  value = azurerm_public_ip.appgw.ip_address
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "aks_oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "acr_login_server" {
  value = azurerm_container_registry.main.login_server
}

output "storage_account_name" {
  value = azurerm_storage_account.main.name
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

output "postgres_fqdn" {
  value = azurerm_postgresql_flexible_server.main.fqdn
}

output "function_default_hostname" {
  value = azurerm_linux_function_app.main.default_hostname
}
