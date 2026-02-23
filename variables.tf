variable "prefix" {
  description = "Project prefix used for naming resources."
  type        = string
  default     = "algproj"
}

variable "location" {
  description = "Primary Azure region (Europe only)."
  type        = string
  default     = "westeurope"
}

variable "student_email" {
  description = "Student e-mail tag value."
  type        = string
  default     = "student@algebra.hr"
}

variable "allowed_jump_source_ips" {
  description = "CIDR list allowed to RDP to jump VM."
  type        = list(string)
}

variable "admin_username" {
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "Windows VM administrator password."
  type        = string
  sensitive   = true
}

variable "postgres_admin_login" {
  type    = string
  default = "pgadmin"
}

variable "postgres_admin_password" {
  type      = string
  sensitive = true
}

variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "jump_vnet_cidr" {
  type    = string
  default = "10.50.0.0/16"
}

variable "core_vnet_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "ssh_public_key" {
  description = "SSH key for AKS Linux profile."
  type        = string
}

variable "function_package_url" {
  description = "Optional ZIP deployment package URL for sample function app code."
  type        = string
  default     = ""
}

variable "filesync_registered_server_id" {
  description = "Registered server ID for Azure File Sync server endpoint (optional)."
  type        = string
  default     = ""
}
