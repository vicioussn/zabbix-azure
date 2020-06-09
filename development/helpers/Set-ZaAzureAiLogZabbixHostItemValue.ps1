function Set-ZaAzureAiLogZabbixHostItemValue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$zabbixHostName,
        [Parameter(Mandatory = $false)][string]$workingDir = ""
    );


    # Authenticating in Zabbix
    $zabbixUrl = "https://<your-zabbix-host>";
    $zabbixServer = "<your-zabbix-host>";
    $zabbixCreds = New-Object System.Management.Automation.PSCredential ("<your-zabbix-user-name>", $(ConvertTo-SecureString "<your-zabbix-user-password>" -AsPlainText -Force));
    $zabbixToken = Get-ZaZabbixAuthToken -url $zabbixUrl -creds $zabbixCreds;
    # /Authenticating in Zabbix


    # Getting AI appId and appKey
    $zabbixHost = Get-ZaZabbixHost -url $zabbixUrl -auth $zabbixToken -hostName $zabbixHostName;
    $zabbixHostMacro = Get-ZaZabbixHostMacro -url $zabbixUrl -auth $zabbixToken -hostId $zabbixHost.hostid;
    $appId = $zabbixHostMacro | Where-Object {$_.macro -eq '{$AIAPPID}'} | Select-Object -ExpandProperty Value;
    $appKey = $zabbixHostMacro | Where-Object {$_.macro -eq '{$AIAPPKEY}'} | Select-Object -ExpandProperty Value;
    # /Getting AI appId and appKey

    
    # Getting items responsible for AI logs
    $zabbixItemPattern = '^azure\.ai\.logs\[([\w\/\-\.]*),([\w\/\-\.]*),([\w\/\-\.]*),?([\w\/\-\.]*)]$';
    [array]$zabbixHostItems = Get-ZaZabbixItem -url $zabbixUrl -auth $zabbixToken -hostName $zabbixHostName | Where-Object {$_.key_ -match $zabbixItemPattern};
    # /Getting items responsible for AI logs


    $counter1 = 1;
    foreach ($zabbixHostItem in $zabbixHostItems)
    {
        try
        {
            Write-Verbose "";
            Write-Verbose "Item $counter1/$($zabbixHostItems.count)";
            Write-Verbose "Parsing item key '$($zabbixHostItem.key_)' and getting variables to make REST request.";
            $itemParse = Select-String -InputObject $zabbixHostItem.key_ -Pattern $zabbixItemPattern;

            $itemResourceName = $itemParse.Matches.groups[1].Value;     # Not needed, possibly
            $itemQuery = $itemParse.Matches.groups[2].Value;            # Usage of this is not implemented yet
            $itemQueryFileName = $itemParse.Matches.groups[3].Value;

            # Update '$itemQueryFileName' with suffix if provided
            $itemQueryFileNameSuffix = $($zabbixHostMacro | Where-Object {$_.macro -eq "{`$$($itemParse.Matches.groups[4].Value.ToUpper())}"} | Select-Object -ExpandProperty Value);
            if ($itemQueryFileNameSuffix -ne "" -and $itemQueryFileNameSuffix)
            {
                $itemQueryFileNameSuffix = $itemQueryFileNameSuffix.ToLower();
                $itemQueryFileNameSuffix = "_" + $itemQueryFileNameSuffix;
                $itemQueryFileName = $itemQueryFileName -replace "\.", "$itemQueryFileNameSuffix.";
            }
            # /Update '$itemQueryFileName' with suffix if provided

            $counter1++;
        }
        catch
        {
            Write-Error "Error while parsing item key '$($zabbixHostItem.key_)'.";
            throw $_;    
        }


        # Getting item last value 'timestamp'
        Write-Verbose "Getting time span for item '$($zabbixHostItem.name)' (id=$($zabbixHostItem.itemid)) to determine period to pull logs from AI.";
        $itemLastValueObject = Get-ZaZabbixItemHistory -auth $zabbixToken -url $zabbixUrl -itemId $zabbixHostItem.itemid -historyType 4;
        if (-not $itemLastValueObject)
        {
            Write-Verbose "Item '$($zabbixHostItem.name)' (id=$($zabbixHostItem.itemid)) has no values (possibly new item?).";
            Write-Verbose "Setting time frame for logs = 90 days.";
            $itemLastValueTime = $(Get-Date).ToUniversalTime().AddDays(-90).ToString("yyyy-MM-ddTHH:mm:ssZ");
            Write-Verbose "Setting time frame to search logs in AI = '$itemLastValueTime'.";
        }
        else
        {
            $itemLastValueTime = $itemLastValueObject.value | ConvertFrom-Json | Select-Object -ExpandProperty timestamp;
            # The following 'IF' statement needed because the 'ConvertFrom-Json' in Powershell Core automatically converts
            # 'timestamp' value to [datetime]. So, to support both Powershell Core and Powershell for Windows, I've included this
            # statement.
            if ($itemLastValueTime -is [datetime])
            {
                $itemLastValueTime = $itemLastValueTime.ToString('o');
            }
            Write-Verbose "Last 'timestamp' value for item '$($zabbixHostItem.name)' (id=$($zabbixHostItem.itemid)) = '$itemLastValueTime'.";
        }
        # /Getting item last value 'timestamp'


        # Getting logs
        [array]$logs = Get-ZaAzureAiLog `
            -appId $appId `
            -appKey $appKey `
            -timeLimit $itemLastValueTime `
            -queryFilePath "$workingDir\aiQueries\$itemQueryFileName";
        # /Getting logs

        $logs = $logs | Sort-Object timestamp;
        
        # Looping through retrieved logs and pushing them to Zabbix
        $counter2 = 1;
        foreach ($log in $logs)
        {
            Write-Verbose "";
            Write-Verbose "Processing log value $counter2/$($logs.count)";
            $logObject = [PSCustomObject]@{
                host = $zabbixHostName;
                key = $zabbixHostItem.key_;
                value = $log | ConvertTo-Json -Depth 100;
                clock = $($log.timestamp | ConvertTo-EpochTime).ToString();
            };
            $send = New-ZaZabbixItemValue -inputObject $logObject -zabbixServer $zabbixServer;

            if (-not $send)
            {
                Write-Error "Error while trying to push log to Zabbix server.";
                throw;
            }

            $counter2++;
        }
        # /Looping through retrieved logs and pushing them to Zabbix
    }


    Write-Verbose "Sending 'azureAi.lastUpdated' semaphore to the Zabbix host.";
    try
    {
        zabbix_sender -z localhost -s $zabbixHostName -k azureAi.lastUpdated -o success;
    }
    catch
    {
        Write-Error "Error while pushing 'azureAi.lastUpdated' semaphore to Zabbix server.";
        throw $_;
    }


    Remove-ZaZabbixAuthToken -auth $zabbixToken -url $zabbixUrl;
    return "success";
}