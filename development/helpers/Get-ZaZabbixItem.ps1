function Get-ZaZabbixItem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$auth,
        [Parameter(Mandatory = $true)][string]$url,
        [Parameter(Mandatory = $true)][string]$hostName
    );
    

    try
    {
        Write-Verbose "Getting items from Zabbix host '$hostName'.";
        
        $params = @{
            body = @{
                "jsonrpc" = "2.0";
                "method" = "item.get";
                "params" = @{
                    "host" = $hostName;
                };
                "id" = 1;
                "auth" = $auth;
            } | ConvertTo-Json;
            uri = "$url/api_jsonrpc.php";
            headers = @{"Content-Type" = "application/json"};
            method = "Post";
        };
        
        $result_json = Invoke-WebRequest @params -UseBasicParsing -Verbose:$false -ErrorAction Stop;
        $result_object = $result_json | ConvertFrom-Json -ErrorAction Stop;
    }
    catch
    {
        Write-Error "Error while getting items from Zabbix host '$hostName'.";
        throw $_;
    }


    if ($result_object.error)
    {
        Write-Error $("***  Error: " + $result_object.error.message + " " + $result_object.error.data);
        throw;
    }
    else
    {
        Write-Verbose "Successfully fetched items objects from '$hostName'.";
        return $result_object.result;
    }
}