# param (
#     [Parameter(Mandatory = $true)][string]$zabbixHostName,
#     [Parameter(Mandatory = $true)][string]$workingDir
# );
Start-Transcript -OutputDirectory "$($pwd.path)\development\logs\" -IncludeInvocationHeader
$workingDir = "$($pwd.path)\development";
$zabbixHostName = "<host-name>"; # Zabbix host name - represents your Azure Resource Group
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

    Write-Host "Removing lock file 'get-azure-metrics-values_$zabbixHostName.lck'.";
    Remove-Item -Path "get-azure-metrics-values_$zabbixHostName.lck" -Force;
}
else
{
    Write-Host "There is a lock file 'get-azure-metrics-values_$zabbixHostName.lck' indicating that another process is already doing same thing.";
}


Stop-Transcript;