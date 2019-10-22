

# -
# - Terraform's modules : rules of the game --> https://www.terraform.io/docs/modules/index.html
# -

# -
# - Data gathering
# -
data "azurerm_resource_group" "rg" {
  name = var.app_service_rg
}

locals {
  location = var.app_service_location == "" ? data.azurerm_resource_group.rg.location : var.app_service_location
  tags     = merge(var.app_service_additional_tags, data.azurerm_resource_group.rg.tags)
}

# -
# - App Service Plan
# -

resource "azurerm_app_service_plan" "asp1" {
  for_each                     = var.app_service_plans
  name                         = "${var.app_service_prefix}-${each.value["prefix"]}-asp${each.value["id"]}"
  resource_group_name          = data.azurerm_resource_group.rg.name
  location                     = local.location
  kind                         = lookup(each.value, "kind", null)                         #(Optional) The kind of the App Service Plan to create. Possible values are Windows (also available as App), Linux, elastic (for Premium Consumption) and FunctionApp (for a Consumption Plan). Defaults to Windows. Changing this forces a new resource to be created.
  maximum_elastic_worker_count = lookup(each.value, "maximum_elastic_worker_count", null) #The maximum number of total workers allowed for this ElasticScaleEnabled App Service Plan.

  sku {
    tier     = each.value["sku_tier"]                   #(Required) Specifies the plan's pricing tier.
    size     = each.value["sku_size"]                   #(Required) Specifies the plan's instance size.
    capacity = lookup(each.value, "sku_capacity", null) #(Optional) Specifies the number of workers associated with this App Service Plan.
  }

  app_service_environment_id = null #(Optional) The ID of the App Service Environment where the App Service Plan should be located. Changing forces a new resource to be created./*
  /*
  #This forces a destroy when adding a new lb --> loadbalancer_id     = lookup(azurerm_lb.lb, each.value["lb_key"])["id"]
  depends_on      = [azurerm_lb.lb]
  loadbalancer_id = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.lb_resource_group_name}/providers/Microsoft.Network/loadBalancers/${var.lb_prefix}-${lookup(var.Lbs, each.value["lb_key"], "wrong_lb_key_in_LbRules")["suffix_name"]}-lb${lookup(var.Lbs, each.value["lb_key"], "wrong_lb_key_in_LbRules")["id"]}"
*/
  reserved         = lookup(each.value, "reserved", null)         #(Optional) Is this App Service Plan Reserved. Defaults to false.
  per_site_scaling = lookup(each.value, "per_site_scaling", null) #(Optional) Can Apps assigned to this App Service Plan be scaled independently? If set to false apps assigned to this plan will scale to all instances of the plan. Defaults to false.
  tags             = local.tags

}

resource "azurerm_app_service" "apps1" {
  for_each            = var.app_services
  name                = "${var.app_service_prefix}-${each.value["prefix"]}-apps${each.value["id"]}"     #(Required) Specifies the name of the App Service. Changing this forces a new resource to be created.
  resource_group_name = data.azurerm_resource_group.rg.name                                             #(Required) The name of the resource group in which to create the App Service.
  location            = local.location                                                                  #(Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created.
  app_service_plan_id = lookup(azurerm_app_service_plan.asp1, each.value["app_service_plan_key"])["id"] #(Required) The ID of the App Service Plan within which to create this App Service.
  app_settings        = lookup(each.value, "app_settings", null)                                        #(Optional) A key-value pair of App Settings.
  auth_settings {
    enabled = lookup(each.value, "enabled", false) #(Required) Is Authentication enabled?
    #active_directory {}
    additional_login_params        = lookup(each.value, "additional_login_params", null)        #(Optional) Login parameters to send to the OpenID Connect authorization endpoint when a user logs in. Each parameter must be in the form "key=value".
    allowed_external_redirect_urls = lookup(each.value, "allowed_external_redirect_urls", null) #(Optional) External URLs that can be redirected to as part of logging in or logging out of the app.
    default_provider               = lookup(each.value, "default_provider", null)               #(Optional) The default provider to use when multiple providers have been set up. Possible values are AzureActiveDirectory, Facebook, Google, MicrosoftAccount and Twitter. NOTE: When using multiple providers, the default provider must be set for settings like unauthenticated_client_action to work.
    #facebook {}
    #google {}
    issuer = lookup(each.value, "issuer", null) #(Optional) Issuer URI. When using Azure Active Directory, this value is the URI of the directory tenant, e.g. https://sts.windows.net/{tenant-guid}/.
    #microsoft {}
    runtime_version               = lookup(each.value, "runtime_version", null)               #(Optional) The runtime version of the Authentication/Authorization module.
    token_refresh_extension_hours = lookup(each.value, "token_refresh_extension_hours", null) #(Optional) The number of hours after session token expiration that a session token can be used to call the token refresh API. Defaults to 72.
    token_store_enabled           = lookup(each.value, "token_store_enabled", null)           #(Optional) If enabled the module will durably store platform-specific security tokens that are obtained during login flows. Defaults to false.
    #twitter {}
    unauthenticated_client_action = lookup(each.value, "unauthenticated_client_action", null) #(Optional) The action to take when an unauthenticated client attempts to access the app. Possible values are AllowAnonymous and RedirectToLoginPage.
  }

  dynamic "storage_account" {
    for_each = lookup(each.value, "storage_accounts", var.null_array)
    content {
      name         = lookup(storage_account.value, "name", null)         #(Required) The name of the storage account identifier.
      type         = lookup(storage_account.value, "type", null)         #(Required) The type of storage. Possible values are AzureBlob and AzureFiles.
      account_name = lookup(storage_account.value, "account_name", null) #(Required) The name of the storage account.
      share_name   = lookup(storage_account.value, "share_name", null)   #(Required) The name of the file share (container name, for Blob storage).
      access_key   = lookup(storage_account.value, "access_key", null)   #(Required) The access key for the storage account.
      mount_path   = lookup(storage_account.value, "mount_path", null)   #(Optional) The path to mount the storage within the site's runtime environment.

    }
  }
/*
  dynamic "connection_string" {
    for_each = lookup(each.value, "connection_strings", var.null_array)
    content {
      name  = lookup(connection_string.value, "", null) #(Required) The name of the Connection String.
      type  = lookup(connection_string.value, "", null) #(Required) The type of the Connection String. Possible values are APIHub, Custom, DocDb, EventHub, MySQL, NotificationHub, PostgreSQL, RedisCache, ServiceBus, SQLAzure and SQLServer.
      value = lookup(connection_string.value, "", null) #(Required) The value for the Connection String.
    }
  }

  client_affinity_enabled = lookup(each.value, "client_affinity_enabled", null) #(Optional) Should the App Service send session affinity cookies, which route client requests in the same session to the same instance?
  client_cert_enabled     = lookup(each.value, "client_cert_enabled", null) #(Optional) Does the App Service require client certificates for incoming requests? Defaults to false.
  enabled                 = lookup(each.value, "enabled", null) #(Optional) Is the App Service Enabled?
  https_only              = lookup(each.value, "https_only", null) #(Optional) Can the App Service only be accessed via HTTPS? Defaults to false.

  logs {

    application_logs {

      dynamic "azure_blob_storage" {
        for_each = lookup(each.value, "application_logs_azure_blob_storage", var.null_array)
        content {
          level             = lookup(azure_blob_storage.value, "level", null)             #(Required) The level at which to log. Possible values include Error, Warning, Information, Verbose and Off. NOTE: this field is not available for http_logs
          sas_url           = lookup(azure_blob_storage.value, "sas_url", null)           #(Required) The URL to the storage container, with a Service SAS token appended. NOTE: there is currently no means of generating Service SAS tokens with the azurerm provider.
          retention_in_days = lookup(azure_blob_storage.value, "retention_in_days", null) #(Required) The number of days to retain logs for.

        }
      }
    }

    http_logs {

      dynamic "file_system" {
        for_each = lookup(each.value, "http_logs_file_system", var.null_array)
        content {
          retention_in_days = lookup(file_system.value, "retention_in_days", null) #(Required) The number of days to retain logs for.
          retention_in_mb   = lookup(file_system.value, "retention_in_mb", null)   #(Required) The maximum size in megabytes that http log files can use before being removed.

        }
      }

      dynamic "azure_blob_storage" {
        for_each = lookup(each.value, "http_logs_azure_blob_storage", var.null_array)
        content {
          sas_url           = lookup(azure_blob_storage.value, "sas_url", null)           #(Required) The URL to the storage container, with a Service SAS token appended. NOTE: there is currently no means of generating Service SAS tokens with the azurerm provider.
          retention_in_days = lookup(azure_blob_storage.value, "retention_in_days", null) #(Required) The number of days to retain logs for.

        }
      }
    }
  }
*/
  dynamic "site_config" {
    for_each = lookup(each.value, "site_config", var.null_array)
    content {
      always_on        = lookup(site_config.value, "always_on", null)        #(Optional) Should the app be loaded at all times? Defaults to false.
      app_command_line = lookup(site_config.value, "app_command_line", null) #(Optional) App command line to launch, e.g. /sbin/myserver -b 0.0.0.0.
      /* Work should be done here to support the cors block
      dynamic "cors" {
        for_each = each.value["cors"]
        content {
          allowed_origins     = lookup(cors.value, "allowed_origins", null)     #(Optional) A list of origins which should be able to make cross-origin calls. * can be used to allow all calls.
          support_credentials = lookup(cors.value, "support_credentials", null) #(Optional) Are credentials supported?
        }
      }
      */
      default_documents         = lookup(site_config.value, "default_documents", null)         #(Optional) The ordering of default documents to load, if an address isn't specified.
      dotnet_framework_version  = lookup(site_config.value, "dotnet_framework_version", null)  #(Optional) The version of the .net framework's CLR used in this App Service. Possible values are v2.0 (which will use the latest version of the .net framework for the .net CLR v2 = lookup(site_config.value, "", null) #currently .net 3.5) and v4.0 (which corresponds to the latest version of the .net CLR v4 = lookup(site_config.value, "", null) #which at the time of writing is .net 4.7.1). For more information on which .net CLR version to use based on the .net framework you're targeting = lookup(site_config.value, "", null) #please see this table. Defaults to v4.0.
      ftps_state                = lookup(site_config.value, "ftps_state", null)                #(Optional) State of FTP / FTPS service for this App Service. Possible values include: AllAllowed, FtpsOnly and Disabled.
      http2_enabled             = lookup(site_config.value, "http2_enabled", null)             #(Optional) Is HTTP2 Enabled on this App Service? Defaults to false.
      ip_restriction            = lookup(site_config.value, "ip_restriction", null)            #(Optional) A List of objects representing ip restrictions as defined below.
      java_version              = lookup(site_config.value, "java_version", null)              #(Optional) The version of Java to use. If specified java_container and java_container_version must also be specified. Possible values are 1.7, 1.8 and 11.
      java_container            = lookup(site_config.value, "java_container", null)            #(Optional) The Java Container to use. If specified java_version and java_container_version must also be specified. Possible values are JETTY and TOMCAT.
      java_container_version    = lookup(site_config.value, "java_container_version", null)    #(Optional) The version of the Java Container to use. If specified java_version and java_container must also be specified.
      local_mysql_enabled       = lookup(site_config.value, "local_mysql_enabled", null)       #(Optional) Is "MySQL In App" Enabled? This runs a local MySQL instance with your app and shares resources from the App Service plan.NOTE: MySQL In App is not intended for production environments and will not scale beyond a single instance. Instead you may wish to use Azure Database for MySQL.
      linux_fx_version          = lookup(site_config.value, "linux_fx_version", null)  == null ? null : lookup(site_config.value, "linux_fx_version_local_file_path", null) == null ? lookup(site_config.value, "linux_fx_version", null) : "${lookup(site_config.value, "linux_fx_version", null)}|${filebase64(lookup(site_config.value, "linux_fx_version_local_file_path", null))}" #(Optional) Linux App Framework and version for the App Service. Possible options are a Docker container (DOCKER|<user/image:tag>), a base-64 encoded Docker Compose file (COMPOSE|${filebase64("compose.yml")}) or a base-64 encoded Kubernetes Manifest (KUBE|${filebase64("kubernetes.yml")}).
      windows_fx_version        = lookup(site_config.value, "windows_fx_version", null)        #(Optional) The Windows Docker container image (DOCKER|<user/image:tag>)
      managed_pipeline_mode     = lookup(site_config.value, "managed_pipeline_mode", null)     #(Optional) The Managed Pipeline Mode. Possible values are Integrated and Classic. Defaults to Integrated.
      min_tls_version           = lookup(site_config.value, "min_tls_version", null)           #(Optional) The minimum supported TLS version for the app service. Possible values are 1.0, 1.1, and 1.2. Defaults to 1.2 for new app services.
      php_version               = lookup(site_config.value, "php_version", null)               #(Optional) The version of PHP to use in this App Service. Possible values are 5.5, 5.6, 7.0, 7.1 and 7.2.
      python_version            = lookup(site_config.value, "python_version", null)            #(Optional) The version of Python to use in this App Service. Possible values are 2.7 and 3.4.
      remote_debugging_enabled  = lookup(site_config.value, "remote_debugging_enabled", null)  #(Optional) Is Remote Debugging Enabled? Defaults to false.
      remote_debugging_version  = lookup(site_config.value, "remote_debugging_version", null)  #(Optional) Which version of Visual Studio should the Remote Debugger be compatible with? Possible values are VS2012, VS2013, VS2015 and VS2017.
      scm_type                  = lookup(site_config.value, "scm_type", null)                  #(Optional) The type of Source Control enabled for this App Service. Defaults to None. Possible values are: BitbucketGit, BitbucketHg, CodePlexGit, CodePlexHg, Dropbox, ExternalGit, ExternalHg, GitHub, LocalGit, None, OneDrive, Tfs, VSO and VSTSRM
      use_32_bit_worker_process = lookup(site_config.value, "use_32_bit_worker_process", null) #(Optional) Should the App Service run in 32 bit mode, rather than 64 bit mode? NOTE: when using an App Service Plan in the Free or Shared Tiers use_32_bit_worker_process must be set to true.
      virtual_network_name      = lookup(site_config.value, "virtual_network_name", null)      #(Optional) The name of the Virtual Network which this App Service should be attached to.
      websockets_enabled        = lookup(site_config.value, "websockets_enabled", null)        #(Optional) Should WebSockets be enabled?
    }
  }

  dynamic "identity" {
    for_each = lookup(each.value, "identity", var.null_array)
    content {
      type         = lookup(identity.value, "type", null)         # (Required) Specifies the identity type of the App Service. Possible values are SystemAssigned (where Azure will generate a Service Principal for you), UserAssigned where you can specify the Service Principal IDs in the identity_ids field, and SystemAssigned, UserAssigned which assigns both a system managed identity as well as the specified user assigned identities. NOTE: When type is set to SystemAssigned, The assigned principal_id and tenant_id can be retrieved after the App Service has been created. More details are available below.
      identity_ids = lookup(identity.value, "identity_ids", null) # (Optional) Specifies a list of user managed identity ids to be assigned. Required if type is UserAssigned.

    }
  }
  tags = lookup(each.value, "", null) #(Optional) A mapping of tags to assign to the resource.
}
