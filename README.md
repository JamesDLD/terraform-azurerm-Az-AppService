Pipeline test
-----
[![Build Status](https://dev.azure.com/jamesdld23/vpc_lab/_apis/build/status/Terraform%20module%20Az-AppService?branchName=master)](https://dev.azure.com/jamesdld23/vpc_lab/_build/latest?definitionId=16&branchName=master)

Requirement
-----
Terraform v0.12.6 and above. 

| Resource | Description |
|------|-------------|
| [azurerm_resource_group](https://www.terraform.io/docs/providers/azurerm/d/resource_group.html) | Get the Resource Group, re use it's tags for the sub resources. |
| [data azurerm_app_service_plan](https://www.terraform.io/docs/providers/azurerm/d/app_service_plan.html) | Option to get existing App Service Plan. |
| [azurerm_app_service_plan](https://www.terraform.io/docs/providers/azurerm/r/app_service_plan.html) | Manages an App Service Plan component. |
| [azurerm_app_service](https://www.terraform.io/docs/providers/azurerm/r/app_service.html) | Manages an App Service (within an App Service Plan). |


Examples
-----
| Name | Description |
|------|-------------|
| docker_python_hello_world | Create an App Service Plan with an App Service using the [Python Hello world docker image](https://hub.docker.com/r/appsvcsample/python-helloworld). |
| php_remote_mysql | Get an existing App Service Plan, create an App Service with environment variables to connect through SSL on an Azure MySQL Database. |