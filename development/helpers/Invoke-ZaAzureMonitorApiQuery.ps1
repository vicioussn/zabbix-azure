function Invoke-ZaAzureMonitorApiQuery {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$authHeader,
        [Parameter(Mandatory = $false)][string]$apiVersion,
        [Parameter(Mandatory = $true)][string]$queryPath,
        [Parameter(Mandatory = $false)][string]$zabbixHostName
    );


    $retries = 5;       # Number of retries
    $retryDelay = 3;    # Seconds between retries


    if ($apiVersion)
    {
        $uri = "{0}?api-version={1}" -f $queryPath, $apiVersion;
    }
    else
    {
        $uri = $queryPath;
    }

    
    $params = @{
        contentType = "application/json";
        headers = @{
            "Authorization" = $authHeader;
        };
        method = "Get";
        uri = $uri;
    }


    $retry = 1;
    while (-not $completed)
    {
        try
        {
            $response = Invoke-RestMethod @params -Verbose:$false -ErrorAction Stop -TimeoutSec 15;
            $completed = $true;
            return $response;
        }
        catch
        {
            if ($retry -gt $retries)
            {
                Write-Error "Error while making REST request to Azure API. $retries retries were made.";
                if ($zabbixHostName)
                {
                    Remove-ZaMonitorScriptLockFile -zabbixHostName $zabbixHostName;
                }

                throw $_;
            }

            Write-Verbose "Error while making REST request to Azure API.";
            Write-Verbose "Retrying $retry/$retries in $retryDelay seconds.";
            Start-Sleep -Seconds $retryDelay;
            $retry++;
        }
    }

}