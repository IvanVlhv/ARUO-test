variable "subscription_id" {
  type        = string
  description = "Azure subscription ID. Required by azurerm provider v4+."
}

variable "tenant_id" {
  type        = string
  description = "Microsoft Entra tenant ID."
}

variable "location" {
  type        = string
  description = "Azure region."
  default     = "westeurope"
}

variable "prefix" {
  type        = string
  description = "Short project prefix."
  default     = "aruo"
}

variable "suffix" {
  type        = string
  description = "Unique suffix for globally unique names. Use lowercase letters and numbers only."
}

variable "student_email" {
  type        = string
  description = "Student email used for tags and optional AAD admin assignment."
  default     = "student@algebra.hr"
}

variable "allowed_jump_source_ips" {
  type        = list(string)
  description = "CIDR list allowed to access the jump VM over RDP."
}

variable "admin_username" {
  type        = string
  description = "Jump VM local admin username."
  default     = "azureadmin"
}

variable "admin_password" {
  type        = string
  description = "Jump VM local admin password."
  sensitive   = true
}

variable "postgres_admin_username" {
  type        = string
  description = "PostgreSQL Flexible Server admin username."
  default     = "pgadmin"
}

variable "postgres_admin_password" {
  type        = string
  description = "PostgreSQL Flexible Server admin password."
  sensitive   = true
}

variable "jump_vm_size" {
  type        = string
  default     = "Standard_B1s"
}

variable "aks_node_vm_size" {
  type        = string
  default     = "Standard_B2ats_v2"
}

variable "aks_node_count" {
  type        = number
  default     = 1
}

variable "function_app_sku_name" {
  type        = string
  description = "App Service plan SKU for Function App. Premium is used to support private networking better than Consumption."
  default     = "EP1"
}

variable "acr_sku" {
  type        = string
  default     = "Standard"
}

variable "tags" {
  type        = map(string)
  description = "Additional custom tags. Mandatory university/student tags are added automatically."
  default     = {}
}
