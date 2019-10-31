#Doc = https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blob-user-delegation-sas-create-powershell
################################################################################
#                                 Variable
################################################################################
$ResourceGroupName = "gal-jdld-infra-sbx-rg1"
$SaName = "jdlddemosa1"
$CtName="appsbck1"

################################################################################
#                                 Action
################################################################################

#Get the Sa and it's Context
$storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $SaName
$ctx= $storageAccount.context 

#Create the container and it's SAS Token
New-AzStorageContainer -context $storageAccount.context -Permission Off -Name $CtName
$Ct=Get-AzStorageContainer -context $storageAccount.context -Name $CtName
$SASToken = New-AzStorageContainerSASToken -context $storageAccount.context -Name $CtName -Permission rwdl -ExpiryTime "16/06/2020 3:14:03 PM"

#Print the SAS URL
Write-output "SAS URL = $($Ct.Context.BlobEndPoint)$($Ct.Name)$SASToken"