function Set-ZaAzureMonitorZabbixHostItemValue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$zabbixHostName,
        [Parameter(Mandatory = $true)][string]$workingDir
    );

    $zabbixUrl = "https://<your-zabbix-host>";

    $zabbixCreds = New-Object System.Management.Automation.PSCredential ("<your-zabbix-user-name>", $(ConvertTo-SecureString "<your-zabbix-user-password>" -AsPlainText -Force));
    $zabbixToken = Get-ZaZabbixAuthToken -url $zabbixUrl -creds $zabbixCreds;

    $zabbixHost = Get-ZaZabbixHost -url $zabbixUrl -auth $zabbixToken -hostName $zabbixHostName;
    $zabbixHostMacro = Get-ZaZabbixHostMacro -url $zabbixUrl -auth $zabbixToken -hostId $zabbixHost.hostid;
    $zabbixItemPattern = '^azure.resource\[([\w\/-]*)\,([\w\s-]*)\,([\w\s]*)\,(\w*)\,?(\w*)\,?(.*)\]$';
    [array]$zabbixHostItems = Get-ZaZabbixItem -url $zabbixUrl -auth $zabbixToken -hostName $zabbixHostName | Where-Object {$_.key_ -match $zabbixItemPattern};

    $resourceGroupName = $zabbixHostMacro | Where-Object {$_.macro -eq '{$RESOURCEGROUP}'} | Select-Object -ExpandProperty Value;
    $subscriptionId = $zabbixHostMacro | Where-Object {$_.macro -eq '{$SUBSCRIPTIONID}'} | Select-Object -ExpandProperty Value;


    $result = New-Object System.Collections.ArrayList;
    $counter = 1;
    foreach ($zabbixHostItem in $zabbixHostItems)
    {
        try
        {
            Write-Verbose "";
            Write-Verbose "Item $counter/$($zabbixHostItems.count)";
            Write-Verbose "Parsing item key '$($zabbixHostItem.key_)' and getting variables to make REST request.";
            $itemParse = Select-String -InputObject $zabbixHostItem.key_ -Pattern $zabbixItemPattern;

            $itemResourceName = $itemParse.Matches.groups[1].Value;
            $itemResourceType = $itemParse.Matches.groups[2].Value;
            $itemMetricName = $itemParse.Matches.groups[3].Value;
            $itemMetricTimeGrain = $itemParse.Matches.groups[4].Value;
            $itemPrimaryAggregationType = $itemParse.Matches.groups[5].Value;
            $itemMetricDimension = $itemParse.Matches.groups[6].Value;
            $itemMetricDimensionValue = $itemParse.Matches.groups[7].Value;
        }
        catch
        {
            Write-Error "Error while parsing item key '$($zabbixHostItem.key_)'.";
            throw $_;    
        }


        # Getting time span to be used in Azure Monitor query
        Write-Verbose "Getting time span for item '$($zabbixHostItem.name)' (id=$($zabbixHostItem.itemid)) to determine period to pull metrics from Azure.";
        $itemLastValue = Get-ZaZabbixItemHistory -auth $zabbixToken -url $zabbixUrl -itemId $zabbixHostItem.itemid;
        if ($itemLastValue)
        {
            Write-Verbose "Latest timestamp for the item: $($itemLastValue[0].clock).";
            $startTime = $($itemLastValue[0].clock | ConvertTo-DateTime).ToString("yyyy-MM-ddTHH:mm:ssZ");
        }
        else
        {
            Write-Verbose "Item '$($zabbixHostItem.name)' (id=$($zabbixHostItem.itemid)) has no values (possibly new item?).";
            $startTime = $(Get-Date).ToUniversalTime().AddDays(-3).ToString("yyyy-MM-ddTHH:mm:ssZ");
        }

        Write-Verbose "Current Epoch time (-3 minutes): $($(Get-Date).AddMinutes(-3).ToUniversalTime() | ConvertTo-EpochTime)."
        $now = $(Get-Date).AddMinutes(-3).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ");
        Write-Verbose "Timespan = '$startTime - $now'.";
        # /Getting time span to be used in Azure Monitor query

        $params = @{
            resourceName = $itemResourceName;
            resourceType = $itemResourceType;
            subscriptionId = $subscriptionId;
            resourceGroupName = $resourceGroupName;
            startTime = $startTime;
            endTime = $now;
            timeGrain = $itemMetricTimeGrain;
            workingDir = $workingDir;
            metricName = $itemMetricName;
            aggregation = $itemPrimaryAggregationType;
            zabbixHostName = $zabbixHostName;
        };
        $metrics = Get-ZaAzureMonitorMetricValue @params;


        Write-Verbose "Building result array for pushing to Zabbix server.";
        foreach ($metric in $metrics)
        {
            $value = @($metric.average, $metric.maximum, $metric.minimum, $metric.total) -ne $null | Select-Object;

            if ($null -ne $value)
            {
                $object = [pscustomobject]@{
                    host = $zabbixHostName;
                    key = $zabbixHostItem.key_;
                    timestamp = $metric.timestamp | ConvertTo-EpochTime;
                    value = $value.ToString().Replace(",", ".");
                };
    
                [void]::$($result.Add($object));
            }
            else
            {
                Write-Verbose "Metric skipped (value = null).";
            }
        }

        $counter++;
    }
    # It's required to sort array by 'timestamp' so Zabbix server can correctly work with calculated triggers
    $result = $result | Sort-Object -Property timestamp;


    Write-Verbose "Writing metrics to 'imports' file.";
    New-Item -Path "$workingDir/imports" -ItemType Directory -ErrorAction SilentlyContinue;
    $fileTimestamp = $(Get-Date).ToUniversalTime().tostring("yyyy-MM-ddTHH-mm-ssZ");
    $fileName = "$workingDir/imports/" + $zabbixHostName + "_" + $fileTimestamp + ".imports";

    # Unknown bug in sending to trapper - first line always failed, so as workaround - duplicate it.
    $isFirstline = $true;
    # Using [System.IO.StreamWriter] because common Powershell cmdlets for file output work very slow in Linux
    try
    {
        $stream = [System.IO.StreamWriter]$fileName;
        foreach ($item in $result)
        {
            if ($isFirstline)
            {
                $line = '"{0}" "{1}" "{2}" "{3}"' -f $item.host, $item.key, $item.timestamp, $item.value;
                $stream.WriteLine($line);
                $isFirstline = $false;
            }
            $line = '"{0}" "{1}" "{2}" "{3}"' -f $item.host, $item.key, $item.timestamp, $item.value;
            $stream.WriteLine($line);
        }
        Write-Verbose "Finished write to file.";
        Write-Verbose "$fileName";
        $stream.Close();
    }
    catch
    {
        Write-Error "Error while writing metrics to 'imports' file '$fileName'.";
        throw $_;
    }


    Write-Verbose "Pushing '$fileName' to Zabbix server.";
    try
    {
        zabbix_sender -z localhost -i $fileName -T -v
    }
    catch
    {
        Write-Error "Error while pushing '$fileName' to Zabbix server.";
        throw $_;
    }


    Write-Verbose "Sending 'azureMonitor.lastUpdated' semaphore to the Zabbix host.";
    try
    {
        zabbix_sender -z localhost -s $zabbixHostName -k azureMonitor.lastUpdated -o success;
    }
    catch
    {
        Write-Error "Error while pushing 'azureMonitor.lastUpdated' semaphore to Zabbix server.";
        throw $_;
    }


    Remove-ZaZabbixAuthToken -auth $zabbixToken -url $zabbixUrl;
}