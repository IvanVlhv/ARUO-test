output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "jump_vm_public_ip" {
  value = module.network.jump_public_ip
}

output "app_gateway_public_ip" {
  value = module.network.appgw_public_ip
}

output "aks_name" {
  value = module.platform.aks_name
}

output "function_hostname" {
  value = module.platform.function_hostname
}

output "postgres_fqdn" {
  value = module.platform.postgres_fqdn
}

output "workload_identity_client_id" {
  value = module.platform.workload_identity_client_id
}
