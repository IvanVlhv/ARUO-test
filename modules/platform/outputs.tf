output "law_id" { value = azurerm_log_analytics_workspace.main.id }
output "jump_vm_id" { value = azurerm_windows_virtual_machine.jump.id }
output "aks_name" { value = azurerm_kubernetes_cluster.main.name }
output "function_hostname" { value = azurerm_linux_function_app.main.default_hostname }
output "postgres_fqdn" { value = azurerm_postgresql_flexible_server.main.fqdn }
output "workload_identity_client_id" { value = azurerm_user_assigned_identity.aks_workload.client_id }
