# -
# - App Service 
# -

output "asp_ids" {
  value = [for x in azurerm_app_service_plan.asp1 : {
    id                        = lookup(x, "id", null)                        #The ID of the App Service Plan component.
    maximum_number_of_workers = lookup(x, "maximum_number_of_workers", null) #The maximum number of workers supported with the App Service Plan's sku.
    }
  ]
}

output "apps_ids" {
  value = [for x in azurerm_app_service.apps1 : {
    id                             = lookup(x, "id", null)                             #The ID of the App Service.
    default_site_hostname          = lookup(x, "default_site_hostname", null)          #The Default Hostname associated with the App Service - such as mysite.azurewebsites.net
    outbound_ip_addresses          = lookup(x, "outbound_ip_addresses", null)          #A comma separated list of outbound IP addresses - such as 52.23.25.3,52.143.43.12
    possible_outbound_ip_addresses = lookup(x, "possible_outbound_ip_addresses", null) #A comma separated list of outbound IP addresses - such as 52.23.25.3,52.143.43.12,52.143.43.17 - not all of which are necessarily in use. Superset of outbound_ip_addresses.
    source_control                 = lookup(x, "source_control", null)                 #A source_control block as defined below, which contains the Source Control information when scm_type is set to LocalGit.
    site_credential                = lookup(x, "site_credential", null)                #A site_credential block as defined below, which contains the site-level credentials used to publish to this App Service.
    identity                       = lookup(x, "identity", null)                       #An identity block as defined below, which contains the Managed Service Identity information for this App Service.
  }]
}
