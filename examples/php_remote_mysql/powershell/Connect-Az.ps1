################################################################################
#                                 Variable
################################################################################
$SecretFile = "../../../secret/main-jdld.json"

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
