function Get-ZaAzureAiLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$appId,
        [Parameter(Mandatory = $true)][string]$appKey,
        [Parameter(Mandatory = $false)][string]$query,
        [Parameter(Mandatory = $false)][string]$queryFilePath,
        [Parameter(Mandatory = $false)][string]$timeLimit
    );

    Write-Verbose "Getting Azure Application Insights logs with parameters:";
    Write-Verbose "appId = '$appId'";
    Write-Verbose "appKey = '$($appKey -replace ".","*")'";
    Write-Verbose "query = '$query'";
    Write-Verbose "queryFilePath = '$queryFilePath'";
    Write-Verbose "timeLimit = '$timeLimit'";


    #region Preparing query
    if ($query)
    {
        if ($timeLimit)
        {
            $query = $query + " | where timestamp > todatetime('$timeLimit')";
        }
        $query = [uri]::EscapeUriString("?query=$query");
    }
    elseif ($queryFilePath)
    {
        try
        {
            # 'Select-String' in the expression below needed to cut off comments in 'kusto' queries (strings with '//' in the beginning).
            $query = Get-Content -Path $queryFilePath -ErrorAction Stop | Select-String -Pattern "^\/\/" -NotMatch;
            if ($timeLimit)
            {
                $query += " | where timestamp > todatetime('$timeLimit')";
            }
            $query = [uri]::EscapeUriString("?query=$query");
        }
        catch
        {
            Write-Error "Error while reading '$queryFilePath' file.";
            throw;
        }
    }
    else
    {
        Write-Error "One of 'query' or 'queryFilePath' parameters must be provided.";
        throw;
    }
    #endregion /Preparing query


    #region Making request
    $headers = @{
        "X-Api-Key" = $appKey;
        "Content-Type" = "application/json";
    };
    $uri = "https://api.applicationinsights.io/v1/apps/$appId/query$query";

    try
    {
        Write-Verbose "Making REST request to the AI API.";
        # Write-Verbose $uri;

        $response = Invoke-RestMethod -Uri $uri -Headers $headers -ErrorAction Stop | Select-Object -ExpandProperty tables;
        Write-Verbose "$($response.rows.count) rows returned.";
    }
    catch
    {
        Write-Error "Error while making REST request to the AI API.";
        throw;
    }
    #endregion /Making request


    #region Formatting output
    Write-Verbose "Formatting response.";
    [array]$result = @();
    $cols = $response.columns;
    #$response.rows | ForEach-Object
    foreach ($row in $response.rows)
    {
        $obj = New-Object -TypeName PSCustomObject;
        for ($i=0; $i -lt $cols.Length; $i++)
        {
            # Checking if the column value is an object
            if ($cols[$i].type -eq "dynamic" -and $row[$i])
            {
                # Write-Verbose "The '$($cols[$i].name)' column is an object, converting it to an object.";
                try
                {
                    $value = $row[$i] | ConvertFrom-Json -ErrorAction Stop;
                    $obj | Add-Member -MemberType NoteProperty -Name $cols[$i].name -Value $value;
                }
                catch
                {
                    Write-Verbose "Error while converting the '$($cols[$i].name)' column to the object. Passing it as a string.";
                    Write-Verbose "$($cols[$i].name) : $($cols[$i].type)";
                    Write-Verbose $row[$i];
                    $obj | Add-Member -MemberType NoteProperty -Name $cols[$i].name -Value $row[$i];
                }
            }
            else
            {
                $obj | Add-Member -MemberType NoteProperty -Name $cols[$i].name -Value $row[$i];
            }
        }
        $result += $obj;
    }
    Write-Verbose "Returning $($result.Count) rows.";
    #endregion /Formatting output

    return $result;
}