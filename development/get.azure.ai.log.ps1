param (
    [Parameter(Mandatory = $true)][string]$zabbixHostName,
    [Parameter(Mandatory = $false)][string]$workingDir = "."
);

Start-Transcript -OutputDirectory "/var/log/azure-scripts/" -IncludeInvocationHeader;

Set-Location $workingDir;

foreach ($file in get-childitem .\helpers -Filter *.ps1)
{
    . $file.FullName
}


$params = @{
    zabbixHostName = $zabbixHostName;
    workingDir = $workingDir;
};

Set-ZaAzureAiLogZabbixHostItemValue @params -Verbose;
Stop-Transcript;