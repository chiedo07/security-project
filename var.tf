variable "azurerm_resource_group_name" {
  description = "sec-rg"
  type        = string
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