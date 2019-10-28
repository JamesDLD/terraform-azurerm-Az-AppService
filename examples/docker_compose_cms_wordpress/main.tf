#Set the terraform backend
terraform {
  backend "azurerm" {
    storage_account_name = "jdlddemosa1"
    container_name       = "tfstate"
    key                  = "Az-AppService.docker_compose_wordpress.tfstate"
    resource_group_name  = "gal-jdld-infra-sbx-rg1"
  }
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
      id                           = "2"        #(Mandatory)
      prefix                       = "cms"      #(Mandatory)
      kind                         = "Linux"    #(Optional) The kind of the App Service Plan to create. Possible values are Windows (also available as App), Linux, elastic (for Premium Consumption) and FunctionApp (for a Consumption Plan). Defaults to Windows. Changing this forces a new resource to be created.
      maximum_elastic_worker_count = null       # The maximum number of total workers allowed for this ElasticScaleEnabled App Service Plan.
      sku_tier                     = "Standard" #(Required) Specifies the plan's pricing tier.
      sku_size                     = "S1"       #(Required) Specifies the plan's instance size.
      sku_capacity                 = null       #(Optional) Specifies the number of workers associated with this App Service Plan.
      ase_key                      = null       #(Optional) The ID of the App Service Environment where the App Service Plan should be located. Changing forces a new resource to be created.
      reserved                     = true       #(Optional) Is this App Service Plan Reserved. Defaults to false.
      per_site_scaling             = null       #(Optional) Can Apps assigned to this App Service Plan be scaled independently? If set to false apps assigned to this plan will scale to all instances of the plan. Defaults to false.
    }
  }
}

variable "app_services" {
  default = {

    wordpress_sample = {
      id                   = "1"         #(Required)
      prefix               = "wordpress" #(Required) Specifies the name of the App Service. Changing this forces a new resource to be created.
      app_service_plan_key = "asp1"      #(Required) The Key from azurerm_app_service_plan map the  of the App Service Plan within which to create this App Service.
      app_settings = {
        "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
      } #(Optional) A key-value pair of App Settings.

      http_logs_file_system = [
        {
          retention_in_days = "2"  #(Optional) Default is 1. The number of days to retain logs for.
          retention_in_mb   = "36" #(Optional) Default is 35. The maximum size in megabytes that http log files can use before being removed.
        },
      ]

      site_config = [
        {
          app_command_line                 = ""        #(Optional) App command line to launch, e.g. /sbin/myserver -b 0.0.0.0.
          linux_fx_version                 = "COMPOSE" #(Optional) Linux App Framework and version for the App Service. Possible options are a Docker container (DOCKER|<user/image:tag>), a base-64 encoded Docker Compose file (COMPOSE|${filebase64("compose.yml")}) or a base-64 encoded Kubernetes Manifest (KUBE|${filebase64("kubernetes.yml")}).
          linux_fx_version_local_file_path = "./dockerfile/ghostinthewires-mysql-wordpress.yml"
        },
      ]
    } #Source = https://github.com/terraform-providers/terraform-provider-azurerm/tree/master/examples/app-service/docker-compose
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
  app_service_prefix          = "jdld"
  app_service_location        = data.azurerm_resource_group.demo.location
  app_service_plans           = var.app_service_plans
  app_services                = var.app_services
  app_service_additional_tags = var.app_service_additional_tags
}

#Output
output "app_service_plans" {
  value = module.Az-AppService-Demo.app_service_plans
}

output "app_service_default_hostnames" {
  value = module.Az-AppService-Demo.app_service_default_hostnames
}

