param (
    [Parameter(Mandatory = $true)][string]$resourceGroup,
    [Parameter(Mandatory = $true)][string]$subscriptionId,
    [Parameter(Mandatory = $true)][string]$resourceType,
    [Parameter(Mandatory = $false)][AllowEmptyString()][string]$metricName,
    [Parameter(Mandatory = $false)][string]$workingDir = "."
);

Set-Location $workingDir;

foreach ($file in get-childitem helpers\ -Filter *.ps1)
{
    . $file.FullName
}


$params = @{
    workingDir = $workingDir;
    resourceGroup = $resourceGroup;
    subscriptionId = $subscriptionId;
    resourceType = $resourceType;
};

if ($metricName)
{
    $params.metricName = $metricName;
}

Get-ZaAzureMonitorMetrics @params;