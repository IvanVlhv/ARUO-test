output "subnet_jump_id" { value = azurerm_subnet.jump.id }
output "subnet_appgw_id" { value = azurerm_subnet.appgw.id }
output "subnet_aks_id" { value = azurerm_subnet.aks.id }
output "subnet_function_id" { value = azurerm_subnet.function.id }
output "subnet_db_id" { value = azurerm_subnet.db.id }
output "subnet_private_endpoints_id" { value = azurerm_subnet.private_endpoints.id }
output "jump_public_ip_id" { value = azurerm_public_ip.jump.id }
output "appgw_public_ip_id" { value = azurerm_public_ip.appgw.id }
output "jump_public_ip" { value = azurerm_public_ip.jump.ip_address }
output "appgw_public_ip" { value = azurerm_public_ip.appgw.ip_address }

output "core_vnet_id" { value = azurerm_virtual_network.core.id }
