function Get-ZaZabbixHostMacro {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$auth,
        [Parameter(Mandatory = $true)][string]$url,
        [Parameter(Mandatory = $true)][string]$hostId
    );
    

    try
    {
        Write-Verbose "Getting macros for Zabbix host ID '$hostId'.";
        
        $params = @{
            body = @{
                "jsonrpc" = "2.0";
                "method" = "usermacro.get";
                "params" = @{
                    "hostids" = $hostId;
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
        Write-Error "Error while getting macros for Zabbix host ID '$hostId'";
        throw $_;
    }
    

    if ($result_object.error)
    {
        Write-Error $("***  Error: " + $result_object.error.message + " " + $result_object.error.data);
        throw;
    }
    else
    {
        Write-Verbose "Successfully fetched macros for Zabbix host ID '$hostId'.";
        return $result_object.result;
    }
}