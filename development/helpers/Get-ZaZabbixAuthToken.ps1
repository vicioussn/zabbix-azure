function Get-ZaZabbixAuthToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][PSCredential]$creds,
        [Parameter(Mandatory = $true)][string]$url
    );
    
    try 
    {
        Write-Verbose "Logging to Zabbix.";
        $params = @{
            body = @{
                "jsonrpc" = "2.0";
                "method" = "user.login";
                "params" = @{
                    "user" = $creds.UserName;
                    "password" = $creds.GetNetworkCredential().Password;
                };
                "id" = 1;
                "auth" = $null;
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
        Write-Error "Error while trying to get Zabbix authorization token.";
        throw $_;
    }
    

    if ($result_object.error)
    {
        Write-Error $("***  Error: " + $result_object.error.message + " " + $result_object.error.data);
        throw;
    }
    else
    {
        Write-Verbose "Successfully logged to Zabbix.";
        return $result_object.result;
    }
}