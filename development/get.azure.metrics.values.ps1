param (
    [Parameter(Mandatory = $true)][string]$zabbixHostName,
    [Parameter(Mandatory = $false)][string]$workingDir = "."
);

Start-Transcript -OutputDirectory "/var/log/azure-script/" -IncludeInvocationHeader;

Set-Location $workingDir;

foreach ($file in get-childitem .\helpers -Filter *.ps1)
{
    . $file.FullName
}


$params = @{
    zabbixHostName = $zabbixHostName;
    workingDir = $workingDir;
};


if (!(Test-Path -Path "get-azure-metrics-values_$zabbixHostName.lck"))
{
    Write-Host "Creating lock file 'get-azure-metrics-values_$zabbixHostName.lck'.";
    New-Item -Path "get-azure-metrics-values_$zabbixHostName.lck";
    
    Set-ZaAzureMonitorZabbixHostItemValue @params -Verbose;

    Remove-ZaMonitorScriptLockFile -zabbixHostName $zabbixHostName -Verbose;
}
else
{
    Write-Host "There is a lock file 'get-azure-metrics-values_$zabbixHostName.lck' indicating that another process is already doing same thing.";
}


Stop-Transcript;