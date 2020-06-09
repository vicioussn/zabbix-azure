function Get-ZaZabbixItemHistory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$auth,
        [Parameter(Mandatory = $true)][string]$url,
        [Parameter(Mandatory = $true)][string]$itemId,
        [Parameter(Mandatory = $false)][int]$historyType = 0,
        [Parameter(Mandatory = $false)][int]$limit = 1
    );


    # 'historyType' parameter:
    # https://www.zabbix.com/documentation/4.4/manual/api/reference/history/get
    # 0 - numeric float
    # 1 - character
    # 2 - log
    # 3 - numeric unsigned
    # 4 - text
    
    try 
    {
        Write-Verbose "Getting Zabbix history for item '$itemId'.";
        
        $params = @{
            body = @{
                "jsonrpc" = "2.0";
                "method" = "history.get";
                "params" = @{
                    "history" = $historyType;
                    "itemids" = $itemId;
                    "sortfield" = "clock";
                    "sortorder" = "DESC";
                    "limit" = $limit;
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
        Write-Error "Error while getting Zabbix history for item '$itemId'.";
        throw $_;
    }

    
    if ($null -ne $result_object.error)
    {
        Write-Error $("***  Error: " + $result_object.error.message + " " + $result_object.error.data);
        throw;
    }
    else
    {
        Write-Verbose "Successfully fetched Zabbix history for item '$itemId'.";
        return $result_object.result;
    }
}