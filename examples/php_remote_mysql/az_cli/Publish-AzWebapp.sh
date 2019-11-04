#Variable
backend_secret_file_id_path="$(Agent.TempDirectory)/$(backend_main_secret_file_id1)"
rg_infra_name="infr-jdld-noprd-rg1"
sa_name="infrasdbx1vpcjdld1"
rg_app_name="apps-jdld-sand1-rg1"
app_service_name="wp-sdbxwordpress-apps1"
container_name="bin"
blob_name="wordpress_db_ssl_conn_via_env_var.zip"
client_id=$(cat $backend_secret_file_id_path | jq -r  '.client_id')
client_secret=$(cat $backend_secret_file_id_path | jq -r  '.client_secret')
tenant_id=$(cat $backend_secret_file_id_path | jq -r  '.tenant_id')
subscription_id=$(cat $backend_secret_file_id_path | jq -r  '.subscription_id')

#Action
echo "Connecting to the Azure tenant id"
login=$(az login --service-principal -u $client_id -p $client_secret --tenant $tenant_id)

echo "Selecting the Azure subscription"
az account set --subscription $subscription_id

echo "Authenticate to the storage account"
json=$(az storage account keys list --account-name $sa_name --resource-group $rg_infra_name)
export AZURE_STORAGE_ACCOUNT=$sa_name
export AZURE_STORAGE_KEY=$(echo $json | jq -r '.[0].value')

echo "Downloading the app service package file..."
az storage blob download --container-name $container_name --name $blob_name --file ./$blob_name 

echo "Deploy ZIP file with Azure CLI..."
az webapp deployment source config-zip --resource-group $rg_app_name --name $app_service_name --src ./$blob_name 