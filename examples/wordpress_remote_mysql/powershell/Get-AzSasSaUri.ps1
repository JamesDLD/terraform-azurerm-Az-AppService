#Doc = https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blob-user-delegation-sas-create-powershell
#https://docs.microsoft.com/en-us/azure/storage/common/storage-sas-overview
################################################################################
#                                 Variable
################################################################################
$ResourceGroupName = "infr-jdld-noprd-rg1"
$SaName = "infrsdbx1vpcjdld1"
$CtName="appsbck1"
$CtName="bin"
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


#Get the blob and create it's SAS Token
$BlobName="wordpress_db_ssl_conn_via_env_var.zip"
$Blob=Get-AzStorageBlob -context $storageAccount.context -Container "bin" -Blob $BlobName
$SASToken = New-AzStorageBlobSASToken -context $storageAccount.context -Container "bin" -Blob $BlobName -Permission rwdl

#Print the SAS URL
Write-output "SAS URL = $($Ct.Context.BlobEndPoint)$($Ct.Name)/$($BlobName)$($SASToken)"
#Sample usage => "WEBSITE_RUN_FROM_PACKAGE" = "https://infrsdbx1vpcjdld1.blob.core.windows.net/bin/wordpress_db_ssl_conn_via_env_var.zip?sv=2019-02-02&sr=b&sig=htOU9snrc2Xlokq2j0EPBuBqvMHgBz18zvZiQDKqyLM%3D&se=2019-10-31T15%3A08%3A20Z&sp=r"

