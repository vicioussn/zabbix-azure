function Get-ZaAzureMonitorMetrics {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$workingDir,
        [Parameter(Mandatory = $true)][string]$resourceGroup,
        [Parameter(Mandatory = $true)][string]$subscriptionId,
        [Parameter(Mandatory = $true)][ValidateSet("appServicePlan","webApp","functionApp","storageAccount","serviceBus","analysisServices","appInsights")][string]$resourceType,
        [Parameter(Mandatory = $false)][string]$metricName
    );

    $azureToken = Get-ZaAzureMonitorAuthorizationSignature -workingDir $workingDir;


    Write-Verbose "Resolving Azure resource API parameters for 'resourceType' = '$resourceType'.";
    $resourceApiParams = Get-ZaAzureResourceApiParameters -resourceType $resourceType;
    Write-Verbose $($resourceApiParams | Out-String);


    Write-Verbose "Building search path for resources.";
    $searchPath = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/{2}/{3}" -f $subscriptionId, $resourceGroup, $resourceApiParams.provider, $resourceApiParams.providerExtension;
    Write-Verbose "searchPath = '$searchPath'.";


    $restParameters = @{
        authHeader = $azureToken.Authorization;
        queryPath = $searchPath;
        apiVersion = $resourceApiParams.providerApiVersion;
    };


    Write-Verbose "Getting resources list using REST request.`n";
    [array]$resources = Invoke-ZaAzureMonitorApiQuery @restParameters | Select-Object -ExpandProperty value;


    if ($resourceApiParams.providerKind)
    {
        Write-Verbose "'providerKind' = '$($resourceApiParams.providerKind)'. Filtering resources by 'kind'.";
        $resources = $resources | Where-Object {$_.kind -eq $resourceApiParams.providerKind};
    }
    Write-Verbose $($resources | Select-Object Name, Type, Kind, Id | Out-String);


    foreach ($resource in $resources)
    {
        $restParameters = @{
            authHeader = $azureToken.Authorization;
            queryPath = "https://management.azure.com{0}/providers/microsoft.insights/metricDefinitions" -f $resource.id;
            apiVersion = "2018-01-01";
        };

        if (-not $metricName)
        {
            Write-Verbose "The '`$metricName' value was not provided.";
            Write-Verbose "Getting available metricName definitions for resourceId = '$($resource.id)'.";
            $metrics = Invoke-ZaAzureMonitorApiQuery @restParameters | Select-Object -ExpandProperty value;
            Write-Verbose $($metrics | Select-Object Name, Unit | Out-String);
        }
        elseif ($metricName -eq "null")
        {
            Write-Verbose "The '`$metricName' value was provided. '`$metricName' = '$metricName'. ";
            Write-Verbose "Request to Azure API for metrics will not be made. Returning dummy metric object.";
            Write-Verbose "This will result in returning just the Azure resource object.";
            [array]$metrics = [PSCustomObject]@{
                name = [PSCustomObject]@{
                    value = "null";
                    localizedValue = "null";
                };
                primaryAggregationType = "null";
                metricAvailabilities = @(
                    [PSCustomObject]@{
                        timeGrain = "null";
                    }
                );
                unit = "null";
            }
            Write-Verbose $($metrics | Select-Object Name, Unit | Out-String);
        }
        else
        {
            Write-Verbose "The '`$metricName' value was provided. '`$metricName' = $metricName.";
            Write-Verbose "Getting metric definition for resourceId = '$($resource.id)'.";
            [array]$metrics = Invoke-ZaAzureMonitorApiQuery @restParameters | Select-Object -ExpandProperty value | Where-Object {$_.name.value -eq $metricName};
            Write-Verbose $($metrics | Select-Object Name, Unit | Out-String);
        }


        foreach ($metric in $metrics)
        {
            if (-not $metric.isDimensionRequired)
            {
                [array]$result += @{
                    "{#RESOURCEID}" = $resource.id;
                    "{#RESOURCENAME}" = $resource.name;
                    "{#RGNAME}" = $resourceGroup;
                    "{#METRICNAME}" = $metric.name.value;
                    "{#METRICDISPLAYNAME}" = $metric.name.localizedValue;
                    "{#TIMEGRAIN}" = $metric.metricAvailabilities[0].timeGrain;
                    "{#PRIMARYAGGREGATIONTYPE}" = $metric.primaryAggregationType;
                };
            }
        }
    }

    '{"data":' + $(ConvertTo-Json $result) + "}";
}