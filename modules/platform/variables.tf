variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "prefix" {
  type = string
}

variable "suffix" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "postgres_admin_login" {
  type = string
}

variable "postgres_admin_password" {
  type      = string
  sensitive = true
}

variable "ssh_public_key" {
  type = string
}

variable "function_package_url" {
  type = string
}

variable "filesync_registered_server_id" {
  type    = string
  default = ""
}

variable "current_object_id" {
  type = string
}

variable "entra_object_id" {
  type = string
}

variable "entra_display_name" {
  type = string
}

variable "subnet_jump_id" {
  type = string
}

variable "subnet_appgw_id" {
  type = string
}

variable "subnet_aks_id" {
  type = string
}

variable "subnet_function_id" {
  type = string
}

variable "subnet_db_id" {
  type = string
}

variable "subnet_private_endpoints_id" {
  type = string
}

variable "core_vnet_id" {
  type = string
}

variable "jump_public_ip_id" {
  type = string
}

variable "appgw_public_ip_id" {
  type = string
}