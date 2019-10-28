#We use here zipdeploy to publish our site content, see https://docs.microsoft.com/fr-fr/azure/app-service/deploy-zip#deploy-war-file
<#

cd ./bin
wget http://wordpress.org/latest.zip
mkdir -p wordpress_wwwroot
unzip latest.zip -d ./wordpress_wwwroot

#Move custom wordpress files (wp-config.php for the MySql connexion and the Microsoft certificate for MySql ssl connexion)
cp ../examples/wordpress_remote_mysql/wordpress_custom_bin/* ./wordpress_wwwroot/wordpress

Prepare the package
cd ./wordpress_wwwroot/wordpress
compress-Archive -Path * -DestinationPath ../wordpress_db_ssl_conn_via_env_var.zip
#>

################################################################################
#                                 Variable
################################################################################
$ZipFileLocation = "../wordpress_db_ssl_conn_via_env_var.zip"
$SecretFile = "../Az-AppService/secret/main-jdld.json"
$ResourceGroupName = "gal-jdld-app-sbx-rg1"
$AppNames = ("jdlddemo-sdbxwordpress-apps1")

################################################################################
#                                 Authentication
################################################################################
#region authentication
Write-Output "Getting the json secret file : $SecretFile"
$Login = Get-Content -Raw -Path $SecretFile | ConvertFrom-Json -AsHashtable -ErrorAction Stop

Write-Output "Generating the credential variable"
$SecureString = ConvertTo-SecureString -AsPlainText $($Login.client_secret) -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $($Login.client_id), $SecureString 

Write-Output "Connecting to the Azure AD Tenant using the json secret file : $SecretFile"
Connect-AzAccount -ServicePrincipal -Credential $credential -TenantId $($Login.tenant_id) -ErrorAction Stop

Write-Output "Getting the Azure subscription contained in the json secret file : $SecretFile"
$AzureRmSubscription = Get-AzSubscription -SubscriptionId $($Login.subscription_id) -ErrorAction Stop

Write-Output "Setting the Azure context based on the subscription contained in the json secret file : $SecretFile"
$AzureRmContext = Get-AzSubscription -SubscriptionName $AzureRmSubscription.Name | Set-AzContext -ErrorAction Stop

Write-Output "Selecting the Azure the subscription contained in the json secret file : $SecretFile"
Select-AzSubscription -Name $AzureRmSubscription.Name -Context $AzureRmContext -Force -ErrorAction Stop
#endregion
################################################################################
#                                 Action
################################################################################

foreach ($AppName in $AppNames) {
    Write-Host "https://$AppName.azurewebsites.net" -ForegroundColor blue
    $title = 'New site'
    $msg = "Do you want to publish a new WordPress$AppName?"
    $options = '&Yes', '&No'
    $default = 2  # 0=Yes, 1=No
    
    do {
        $response = $Host.UI.PromptForChoice($title, "$msg", $options, $default)
        if ($response -eq 0) {
            Write-Host "Publishing WordPress on App Service : $AppName" -ForegroundColor Green
            Publish-AzWebapp -ResourceGroupName $ResourceGroupName -Name $AppName -ArchivePath $ZipFileLocation

        }
        elseif ($response -eq 1) {
            Write-Host "Will not publish"
        }
    } until ($response -eq 0 -or $response -eq 1)
}

/Users/jamesdumontledouarec/Documents/GitHub/terraform-module/Az-AppService/bin/wordpress_wwwroot/wordpress_db_ssl_conn_via_env_var.zip

<#
$username = "<deployment-user>"
$password = "<deployment-password>"
$apiUrl = "https://$AppName.scm.azurewebsites.net/api/deployments"
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))
$userAgent = "powershell/1.0"
Invoke-RestMethod -Uri $apiUrl -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent $userAgent -Method GET
#>

