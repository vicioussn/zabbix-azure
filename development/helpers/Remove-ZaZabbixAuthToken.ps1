function Remove-ZaZabbixAuthToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$auth,
        [Parameter(Mandatory = $true)][string]$url
    );
    
    
    try 
    {
        Write-Verbose "Logging out from Zabbix.";
        $params = @{
            body = @{
                "jsonrpc" = "2.0";
                "method" = "user.logout";
                "params" = @();
                "id" = 1;
                "auth" = $auth;
            } | ConvertTo-Json;
            uri = "$url/api_jsonrpc.php";
            headers = @{"Content-Type" = "application/json"};
            method  = "Post";
        };
        
        $result_json = Invoke-WebRequest @params -UseBasicParsing -Verbose:$false -ErrorAction Stop;
        $result_object = $result_json | ConvertFrom-Json -ErrorAction Stop;
    }
    catch
    {
        Write-Error "Error while trying logout from Zabbix.";
        throw $_;
    }
    

    if ($result_object.error)
    {
        Write-Error $("***  Error: " + $result_object.error.message + " " + $result_object.error.data);
        throw;
    }
    else
    {
        Write-Verbose "Successfully logged out from Zabbix.";
        return $result_object.result;
    }
}