# param (
#     [Parameter(Mandatory = $true)][string]$zabbixHostName,
#     [Parameter(Mandatory = $true)][string]$workingDir
# );

$workingDir = "/usr/lib/zabbix/externalscripts/";
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

Set-ZaZabbixItemValue @params -Verbose;