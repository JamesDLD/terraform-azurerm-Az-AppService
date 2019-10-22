#Set the terraform backend
terraform {
  backend "local" {}
}

#Set the Provider
provider "azurerm" {
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}

#Set authentication variables
variable "tenant_id" {
  description = "Azure tenant Id."
}

variable "subscription_id" {
  description = "Azure subscription Id."
}

variable "client_id" {
  description = "Azure service principal application Id."
}

variable "client_secret" {
  description = "Azure service principal application Secret."
}

#Set resource variables

variable "app_service_plans" {
  default = {

    asp1 = {
      id       = "1"        #(Mandatory)
      prefix   = "jdld"     #(Mandatory)
      kind     = "Linux"    #(Optional) The kind of the App Service Plan to create. Possible values are Windows (also available as App), Linux, elastic (for Premium Consumption) and FunctionApp (for a Consumption Plan). Defaults to Windows. Changing this forces a new resource to be created.
      sku_tier = "Standard" #(Required) Specifies the plan's pricing tier.
      sku_size = "S1"       #(Required) Specifies the plan's instance size.
      reserved = true       #(Optional) Is this App Service Plan Reserved. Defaults to false.
    }
  }
}

variable "app_services" {
  default = {

    python_sample = {
      id                   = "1"            #(Mandatory)
      prefix               = "dockerpython" #(Required) Specifies the name of the App Service. Changing this forces a new resource to be created.
      app_service_plan_key = "asp1"         #(Required) The Key from azurerm_app_service_plan map the  of the App Service Plan within which to create this App Service.
      app_settings = {
        "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
        "DOCKER_REGISTRY_SERVER_URL"          = "https://index.docker.io"
      }
      site_config = [
        {
          app_command_line = ""                                             #(Optional) App command line to launch, e.g. /sbin/myserver -b 0.0.0.0.
          linux_fx_version = "DOCKER|appsvcsample/python-helloworld:latest" #(Optional) Linux App Framework and version for the App Service. Possible options are a Docker container (DOCKER|<user/image:tag>), a base-64 encoded Docker Compose file (COMPOSE|${filebase64("compose.yml")}) or a base-64 encoded Kubernetes Manifest (KUBE|${filebase64("kubernetes.yml")}).
        },
      ]
    }
  }
}

variable "app_service_additional_tags" {
  default = {
    iac = "terraform"
  }
}

#Prerequisite
data "azurerm_resource_group" "demo" {
  name = "gal-jdld-app-sbx-rg1"
}

#Call module/Resource
module "Az-AppService-Demo" {
  source                      = "../../" #""JamesDLD/Az-AppService/azurerm"
  app_service_rg              = data.azurerm_resource_group.demo.name
  app_service_prefix          = "pythonhello"
  app_service_location        = data.azurerm_resource_group.demo.location
  app_service_plans           = var.app_service_plans
  app_services                = var.app_services
  app_service_additional_tags = var.app_service_additional_tags
}


#Output
output "asp_ids" {
  value = module.Az-AppService-Demo.asp_ids
}

output "apps_ids" {
  value = module.Az-AppService-Demo.apps_ids
}

