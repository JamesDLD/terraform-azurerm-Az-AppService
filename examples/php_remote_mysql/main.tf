#Set the terraform backend
terraform {
  backend "azurerm" {
    storage_account_name = "infrasdbx1vpcjdld1"
    container_name       = "tfstate"
    key                  = "Az-AppService.wordpress_remote_mysql.tfstate"
    resource_group_name  = "infr-jdld-noprd-rg1"
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

variable "rg_name" {
  description = "Resource group name where the resources will be managed."
  default     = "apps-jdld-sand1-rg1"
}

variable "app_service_plans" {
  default = {

    asp1 = {
      id       = "1"        #(Mandatory)
      prefix   = "sdbx"     #(Mandatory)
      kind     = "Linux"    #(Optional) The kind of the App Service Plan to create. Possible values are Windows (also available as App), Linux, elastic (for Premium Consumption) and FunctionApp (for a Consumption Plan). Defaults to Windows. Changing this forces a new resource to be created.
      sku_tier = "Standard" #"Basic" #(Required) Specifies the plan's pricing tier.
      sku_size = "S1"       #"B1"    #(Required) Specifies the plan's instance size.
      reserved = true       #(Optional) Is this App Service Plan Reserved. Defaults to false.
    }
  }
}

variable "app_services" {
  default = {

    wordpress_sample = {
      id                   = "1"             #(Required)
      prefix               = "sdbxwordpress" #(Required) Specifies the name of the App Service. Changing this forces a new resource to be created.
      app_service_plan_key = "asp1"          #(Required) The Key from azurerm_app_service_plan map the  of the App Service Plan within which to create this App Service.
      db_name              = "demo_wordpress"

      site_config = [
        {
          linux_fx_version = "PHP|7.3" #(Optional) Linux App Framework and version for the App Service. Possible options are a Docker container (DOCKER|<user/image:tag>), a base-64 encoded Docker Compose file (COMPOSE|${filebase64("compose.yml")}) or a base-64 encoded Kubernetes Manifest (KUBE|${filebase64("kubernetes.yml")}).
        },
      ]

      app_settings = {
        "DATABASE_HOST"     = "demo-jdld-mysql1.mysql.database.azure.com:3306"
        "DATABASE_NAME"     = "demo_wordpress"
        "DATABASE_USERNAME" = "mysqladminun@demo-jdld-mysql1"
        "DATABASE_PASSWORD" = "HaSh1CoR3!"
        "MYSQL_SSL_CA"      = "BaltimoreCyberTrustRoot.crt.pem"
      } #(Optional) A key-value pair of App Settings.

    }
  }
}

#Prerequisite
data "azurerm_resource_group" "demo" {
  name = var.rg_name
}

#Call module/Resource
module "Az-AppService-Demo" {
  source = "git::https://github.com/JamesDLD/terraform-azurerm-Az-AppService.git//?ref=master"
  #source                      = "../../" 
  #source                      = "JamesDLD/Az-AppService/azurerm"
  app_service_rg              = data.azurerm_resource_group.demo.name
  app_service_prefix          = "wp"
  app_service_location        = data.azurerm_resource_group.demo.location
  app_service_plans           = var.app_service_plans
  app_services                = var.app_services
  app_service_additional_tags = {}
}

resource "azurerm_mysql_server" "demo" {
  name                = "demo-jdld-mysql1"
  location            = data.azurerm_resource_group.demo.location
  resource_group_name = data.azurerm_resource_group.demo.name

  sku {
    name     = "GP_Gen5_2" #"B_Gen5_2"
    capacity = 2
    tier     = "GeneralPurpose" #"Basic" #NOTE: MySQL Virtual Network Rules can only be used with SKU Tiers of GeneralPurpose or MemoryOptimized
    family   = "Gen5"
  }

  storage_profile {
    storage_mb            = 5120
    backup_retention_days = 7
    geo_redundant_backup  = "Disabled"
  }

  administrator_login          = "mysqladminun"
  administrator_login_password = "HaSh1CoR3!"
  version                      = "5.7"
  ssl_enforcement              = "Enabled"
  tags                         = data.azurerm_resource_group.demo.tags
}

resource "azurerm_mysql_database" "wordpress_dbs" {
  for_each            = var.app_services
  name                = each.value["db_name"]
  resource_group_name = data.azurerm_resource_group.demo.name #(Required) The name of the resource group in which to create the App Service.
  server_name         = azurerm_mysql_server.demo.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}
/*
Currently generating a bug with "provider.azurerm v1.36.1" when using the Terraform Destroy cmdlet
resource "azurerm_mysql_firewall_rule" "outbound_ip_addresses" {
  count               = 5
  name                = "outbound_ip_addresses${count.index}"
  resource_group_name = data.azurerm_resource_group.demo.name
  server_name         = azurerm_mysql_server.demo.name
  start_ip_address    = element(split(",", module.Az-AppService-Demo.app_services[0].outbound_ip_addresses), count.index)
  end_ip_address      = element(split(",", module.Az-AppService-Demo.app_services[0].outbound_ip_addresses), count.index)
}

resource "azurerm_mysql_firewall_rule" "possible_outbound_ip_addresses" {
  count               = 10
  name                = "possible_outbound_ip_addresses${count.index}"
  resource_group_name = data.azurerm_resource_group.demo.name
  server_name         = azurerm_mysql_server.demo.name
  start_ip_address    = element(split(",", module.Az-AppService-Demo.app_services[0].possible_outbound_ip_addresses), count.index)
  end_ip_address      = element(split(",", module.Az-AppService-Demo.app_services[0].possible_outbound_ip_addresses), count.index)
}
*/
#Output

output "app_service_default_hostnames" {
  value = module.Az-AppService-Demo.app_service_default_hostnames
}

