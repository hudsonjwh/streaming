#!/bin/bash
az login

resource_group="stream-analytics-rg"
account_name="streamstoragehudsonjwh"
location="southcentralus"
stream_job_name="processblob-sa-job"
input_container="input"
output_container="output"

account_key=$(az storage account keys list -n $account_name  -g $resource_group --query "[0].value" --output tsv)

az storage container list --account-name $account_name --account-key $account_key --auth-mode key --query "[].name"

az storage blob list --account-name $account_name --container-name $input_container --account-key $account_key --auth-mode key  --query "[].name"
az storage blob list --account-name $account_name --container-name $output_container --account-key $account_key --auth-mode key --query "[].name"

az stream-analytics job list --query "[].{name:name,jobState:jobState}"