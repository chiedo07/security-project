variable "azurerm_resource_group_name" {
  description = "resource group"
  type        = string
  default = "sec-reg"
}

variable "admin_password" {
  description = "vm password"
  type        = string
  sensitive   = true
}


variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "project_name" {
  description = "security-project"
  type        = string
}

variable "tags" {
  description = "sec-tag"
  type        = map(string)
  default = {
    Project     = "Azure-Security-Demo"
    Environment = "Development"
  }
}
