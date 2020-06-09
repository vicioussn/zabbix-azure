function Remove-ZaMonitorScriptLockFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$zabbixHostName
    );

    Write-Host "Removing lock file 'get-azure-metrics-values_$zabbixHostName.lck'.";
    Remove-Item -Path "get-azure-metrics-values_$zabbixHostName.lck" -Force;
}