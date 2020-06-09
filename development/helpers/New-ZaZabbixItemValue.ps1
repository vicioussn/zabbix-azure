Function New-ZaZabbixItemValue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$zabbixServer,
        [Parameter(Mandatory = $false)][ValidateRange(1,65535)][int]$zabbixPort = "10051",
        [Parameter(ParameterSetName="Set1")]$inputObject,
        [Parameter(ParameterSetName="Set2")][string]$jsonString
    )


    Write-Verbose "Sending value to Zabbix server.";
    if ($inputObject)
    {
        Write-Verbose "Converting input object to JSON string.";
        $header = @('host','key','value','clock');
        $json = [pscustomobject][ordered]@{
            request = "sender data";
            data = @(
                $InputObject | Select-Object -Property @(
                    @{'Name' = 'host'; Expression = {$_.$($Header[0])}},
                    @{'Name' = 'key'; Expression = {$_.$($Header[1])}},
                    @{'Name' = 'value'; Expression = {$_.$($Header[2])}},
                    @{'Name' = 'clock'; Expression = {$_.$($Header[3])}}
                );
            )
        } | ConvertTo-Json -Compress;
    }
    elseif ($jsonString)
    {
        Write-Verbose "Validating input JSON string.";
        $json = $jsonString | ConvertFrom-Json | ConvertTo-Json -Compress;
    }
    else
    {
        Write-Error "Input data not found";
        throw;
    }
     

    try
    {
        # Write-Verbose $json;
        Write-Verbose "Converting JSON string to byte.";
        [byte[]]$header = @([System.Text.Encoding]::ASCII.GetBytes('ZBXD')) + [byte]1;
        [byte[]]$length = @([System.BitConverter]::GetBytes($([long]$json.Length)));
        [byte[]]$data = @([System.Text.Encoding]::ASCII.GetBytes($json));
         
        $all = $header + $length + $data;
    }
    catch
    {
        Write-Error "Error while converting JSON string to byte.";
        throw;
    }

     
    try
    {
        Write-Verbose "Making TCP request to push data to Zabbix server.";
        $socket = New-Object System.Net.Sockets.Socket ([System.Net.Sockets.AddressFamily]::InterNetwork, [System.Net.Sockets.SocketType]::Stream, [System.Net.Sockets.ProtocolType]::Tcp);
        $socket.Connect($zabbixServer, $zabbixPort);
        $socket.Send($all) | Out-Null;
        [byte[]]$buffer = New-Object System.Byte[] 1000;
        [int]$receivedLength = $socket.Receive($buffer);
        $socket.Close();
    }
    catch
    {
        Write-Error "TCP-level error while talking to Zabbix server.";
        throw;
    }
    $received = [System.Text.Encoding]::ASCII.GetString(@($buffer[13 .. ($receivedLength - 1)]));


    try
    {
        Write-Verbose "Validating response from Zabbix server.";
        $received = $received | ConvertFrom-Json;
        if ($received.response -ne "success" -or $received.info -notmatch "failed: 0")
        {
            Write-Error "Non-success message received from Zabbix server.";
            throw;
        }
        else
        {
            return $true;
        }
    }
    catch
    {
        Write-Error "Error while converting the output to a JSON string, the server might have rejected invalid data.";
        throw;
    }
}