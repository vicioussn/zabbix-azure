# param (
#     [Parameter(Mandatory = $true)][string]$resourceGroup,
#     [Parameter(Mandatory = $true)][string]$subscriptionId,
#     [Parameter(Mandatory = $true)][ValidateSet("appServicePlan","webApp","functionApp","storageAccount","serviceBus")][string]$resourceType,
#     [Parameter(Mandatory = $false)][string]$workingDir = "."
# );

# Set-Location $workingDir;


foreach ($file in get-childitem .\development\helpers -Filter *.ps1)
{
    . $file.FullName
}


$params = @{
    workingDir = "$($pwd.path)\development";
    $zabbixHostName = "<host-name>"; # Zabbix host name - represents your Azure Resource Group
    subscriptionId = "<subscription-id>";
    resourceType = "analysisServices";
    metricName = "null";
};

# $params = @{
#     workingDir = $workingDir;
#     resourceGroup = $resourceGroup;
#     subscriptionId = $subscriptionId;
#     resourceType = $resourceType;
# };

Get-ZaAzureMonitorMetrics @params -Verbose;