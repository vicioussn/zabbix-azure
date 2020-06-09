function Get-ZaAzureMonitorAuthorizationSignature {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)][string]$workingDir
    )

    if(-not $workingDir) { $workingDir = Get-Location | Select-Object -ExpandProperty Path; }
    Write-Verbose "Logging to Azure.";

    
    if (-not (Test-Path -Path "$workingDir/azure.json"))
    {
        Write-Verbose "There is no 'azure.json' file exist.";
        $token = Get-ZaAzureMonitorToken;
        $token | Select-Object expires_on, access_token | ConvertTo-Json | Out-File -FilePath "$workingDir/azure.json" -Encoding UTF8;
    }
    elseif ((Get-Item "$workingDir/azure.json").Length -lt 10)
    {
        Write-Verbose "'azure.json' file exist but has 0 size.";
        $token = Get-ZaAzureMonitorToken;
        $token | Select-Object expires_on, access_token | ConvertTo-Json | Out-File -FilePath "$workingDir/azure.json" -Encoding UTF8;
    }
    else
    {
        $token = Get-Content -Path "$workingDir/azure.json" | ConvertFrom-Json;
        if ($token.expires_on.ToInt64($null) - [int64]((Get-Date).ToUniversalTime() - (Get-Date "1/1/1970")).TotalSeconds -lt 600)
        {
            Write-Verbose "Token expired.";
            $token = Get-ZaAzureMonitorToken;
            $token | Select-Object expires_on, access_token | ConvertTo-Json | Out-File -FilePath "$workingDir/azure.json" -Encoding UTF8;
        }
    }

    $header = @{
        "Content-Type" = "application\json";
        Authorization = $("Bearer " + $token.access_token);
    };

    Write-Verbose "Azure Monitor API header built.";
    return $header;
}

#Get-ZaAzureMonitorAuthorizationSignature -Verbose