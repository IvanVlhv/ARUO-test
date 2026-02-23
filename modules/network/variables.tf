variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "prefix" { type = string }
variable "suffix" { type = string }
variable "tags" { type = map(string) }
variable "allowed_jump_source_ips" { type = list(string) }
variable "core_vnet_cidr" { type = string }
variable "jump_vnet_cidr" { type = string }
