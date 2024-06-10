#!/bin/bash
az login

resource_group="stream-analytics-rg"
stream_job_name="processblob-sa-job"

az stream-analytics job stop --job-name $stream_job_name --resource-group $resource_group --no-wait
az stream-analytics job delete --job-name $stream_job_name --resource-group $resource_group --no-wait -y

az group delete --resource-group $resource_group --no-wait -y

sleep 30

az group list --query "[].name"