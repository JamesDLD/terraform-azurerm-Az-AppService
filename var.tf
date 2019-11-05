# -
# - Core object
# -
variable "app_service_location" {
  description = "App Service resources location if different that the resource group's location."
  type        = string
  default     = ""
}

variable "app_service_additional_tags" {
  description = "Additional tags for the App Service resources, in addition to the resource group tags."
  type        = map(string)
  default     = {}
}

variable "app_service_prefix" {
  description = "App Service resourcess name prefix."
  type        = string
}

variable "app_service_rg" {
  description = "The App Service resources group name."
  type        = string
}

# -
# - Main resources
# -
variable "app_service_plans" {
  description = "The App Services plans with their properties."
  type        = any
}

variable "existing_app_service_plans" {
  description = "Existing App Services plans."
  type        = any
  default     = {}
}


variable "app_services" {
  description = "The App Services with their properties."
  type        = any
}

# -
# - Other
# -
variable "null_array" {
  description = ""
  default     = []
}
