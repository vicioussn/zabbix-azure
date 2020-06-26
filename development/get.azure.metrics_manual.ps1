
foreach ($file in get-childitem .\development\helpers -Filter *.ps1)
{
    . $file.FullName
}


$params = @{
    workingDir = "$($pwd.path)\development";
    zabbixHostName = "<host-name>"; # Zabbix host name - represents your Azure Resource Group
    subscriptionId = "<subscription-id>";
    resourceType = "vm";
    #metricName = "null";
};

# $params = @{
#     workingDir = $workingDir;
#     resourceGroup = $resourceGroup;
#     subscriptionId = $subscriptionId;
#     resourceType = $resourceType;
# };

Get-ZaAzureMonitorMetrics @params -Verbose;