pwsh -File /usr/lib/zabbix/externalscripts/get.azure.metrics.ps1 -resourceGroup $1 -subscriptionId $2 -resourceType $3 -metricName "$4" -workingDir /usr/lib/zabbix/externalscripts/