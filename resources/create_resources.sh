#!/bin/bash
az login

resource_group="stream-analytics-rg"
account_name="streamstoragehudsonjwh"
location="southcentralus"
stream_job_name="processblob-sa-job"
input_container="input"
output_container="output"

az group create --location  $location -n $resource_group 

az storage account create -n $account_name -g $resource_group \
--access-tier Hot --kind StorageV2 --sku Standard_LRS \
--public-network-access Enabled --min-tls-version TLS1_2 \
--allow-blob-public-access false --allow-shared-key-access true

export account_key=$(az storage account keys list -n $account_name  -g $resource_group --query "[0].value" --output tsv)

az storage container create --account-name $account_name  -n $input_container --auth-mode key --account-key $account_key
az storage container create --account-name $account_name  --n $output_container --auth-mode key --account-key $account_key

az storage blob upload -f ./resources/SEN01.json --account-name $account_name -c input --account-key $account_key

az stream-analytics job create --job-name $stream_job_name \
--resource-group $resource_group \
--arrival-max-delay 5 \
--compatibility-level "1.2" \
--data-locale "en-us" \
--location "South Central US" \
--output-error-policy "Drop"

input_container_string="{\"type\":\"Stream\",\"serialization\":{\"type\":\"Json\",\"properties\":{\"encoding\":\"UTF8\"}},\"datasource\":{\"type\":\"Microsoft.Storage/Blob\",\"properties\":{\"container\":\"input\",\"pathPattern\":\"\",\"storageAccounts\":[{\"accountKey\":\"$account_key\",\"accountName\":\"streamstoragehudsonjwh\"}]}}}"
output_container_string="{\"type\":\"Microsoft.Storage/Blob\",\"properties\":{\"container\":\"output\",\"dateFormat\":\"yyyy/MM/dd\",\"pathPattern\":\"{date}T{time}\",\"storageAccounts\":[{\"accountKey\":\"$account_key\",\"accountName\":\"streamstoragehudsonjwh\"}],\"timeFormat\":\"HH-mm\"}}"

az stream-analytics input create -n input --job-name $stream_job_name  -g $resource_group  \
--properties $input_container_string 

az stream-analytics output create -n output --job-name $stream_job_name -g $resource_group \
--datasource $output_container_string \
--serialization "{\"type\":\"Json\",\"properties\":{\"format\":\"Array\",\"encoding\":\"UTF8\"}}"


az stream-analytics transformation create --job-name $stream_job_name  \
--resource-group $resource_group \
--saql "SELECT input.TempratureCelcius, input.SensorId  INTO [output] FROM [input]" \
--streaming-units 1 \
--transformation-name "transformation"

az stream-analytics job start --job-name $stream_job_name --resource-group $resource_group  --output-start-mode "JobStartTime" --no-wait

