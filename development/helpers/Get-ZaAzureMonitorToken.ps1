function Get-ZaAzureMonitorToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)][string]$clientId = "<your-azure-app-id>",
        [Parameter(Mandatory = $false)][string]$clientSecret = "<your-azure-app-secret>",
        [Parameter(Mandatory = $false)][string]$tenantId = "<your-azure-ad-tenant-id>"
    )

    Write-Verbose "Getting new Azure Monitor token.";
    Write-Verbose "tenantId = $tenantId";
    Write-Verbose "clientId = $clientId";

    try 
    {
        $token = Invoke-RestMethod `
            -Uri "https://login.microsoftonline.com/$tenantId/oauth2/token?api-version=1.0" `
            -Method Post `
            -Body @{
                "grant_type" = "client_credentials";
                "resource" = "https://management.core.windows.net/";
                # resource = https://management.azure.com
                "client_id" = $clientId;
                "client_secret" = $clientSecret;
            } `
            -TimeoutSec 15;
    }
    catch 
    {
        Write-Error "Error while getting Azure Monitor token.";
        throw $_;
    }

    return $token;
}