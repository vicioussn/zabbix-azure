function Get-ZaAzureMonitorMetricValue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$resourceName,
        [Parameter(Mandatory = $true)][string]$resourceType,
        [Parameter(Mandatory = $true)][string]$subscriptionId,
        [Parameter(Mandatory = $true)][string]$resourceGroupName,
        [Parameter(Mandatory = $true)][string]$startTime,
        [Parameter(Mandatory = $true)][string]$endTime,
        [Parameter(Mandatory = $true)][string]$timeGrain,
        [Parameter(Mandatory = $true)][string]$workingDir,
        [Parameter(Mandatory = $true)][string]$metricName,
        [Parameter(Mandatory = $true)][string]$aggregation,
        [Parameter(Mandatory = $true)][string]$zabbixHostName
    )


    $resourceApiParams = Get-ZaAzureResourceApiParameters -resourceType $resourceType;
    $authHeader = $(Get-ZaAzureMonitorAuthorizationSignature -workingDir $workingDir).Authorization;


    Write-Verbose "Getting metric values from Azure Monitor with parameters:";
    Write-Verbose "- resourceName = '$resourceName'";
    Write-Verbose "- resourceType = '$resourceType'";
    Write-Verbose "- subscriptionId = '$subscriptionId'";
    Write-Verbose "- resourceGroupName = '$resourceGroupName';";
    Write-Verbose "- timeSpan = '$startTime - $endTime'";
    Write-Verbose "- timeGrain = '$timeGrain'";
    Write-Verbose "- metricName = '$metricName'";

    
    # https://docs.microsoft.com/en-us/azure/azure-monitor/platform/rest-api-walkthrough
    # https://docs.microsoft.com/en-us/rest/api/monitor/metrics/list
    # https://management.azure.com/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/azmon-rest-api-walkthrough
    # /providers/Microsoft.Storage/storageAccounts/ContosoStorage/providers/microsoft.insights
    # /metrics?metricnames=Transactions&timespan=2018-03-01T02:00:00Z/2018-03-01T02:05:00Z&`$filter=${filter}&interval=PT1M&aggregation=Total&top=3&orderby=Total desc&api-version=2018-01-01
    Write-Verbose "Building URI to pull metrics from Azure Monitor.";
    $uri = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/{2}/{3}/{4}/providers/microsoft.insights/metrics?timespan={5}&interval={6}&api-version={7}&metricnames={8}&aggregation={9}" -f `
        $subscriptionId, `                                      # 0
        $resourceGroupName, `                                   # 1
        $resourceApiParams.provider, `                          # 2
        $resourceApiParams.providerExtension, `                 # 3
        $resourceName, `                                        # 4
        "$startTime/$endTime", `                                # 5
        $timeGrain, `                                           # 6
        "2018-01-01", `                                         # 7
        $metricName, `                                          # 8
        $aggregation;                                           # 9
    Write-Verbose "URI: $uri";

    
    $response = Invoke-ZaAzureMonitorApiQuery -authHeader $authHeader -queryPath $uri -zabbixHostName $zabbixHostName -ErrorAction Stop;
    try
    {
        $metrics = $response.value.timeseries.data;
    }
    catch
    {
        Write-Error "Error while getting values from Azure Monitor API.";
        throw $_;
    }


    # $value = @($metrics[0].average, $metrics[0].maximum, $metrics[0].minimum, $metrics[0].total) -ne $null | Select-Object;
    # if ($null -eq $value)
    # {
    #     Write-Error "Error while trying to parse data from Azure Monitor API. Possibly, no actual values were returned?";
    #     # throw;
    # }


    Write-Verbose "Successfully fetched metrics values.";
    Write-Verbose "Count = $($metrics.count).";

    return $metrics;
}