function Get-ZaAzureResourceApiParameters {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("appServicePlan","webApp","functionApp","storageAccount","serviceBus","analysisServices","appInsights")]
        [string]$resourceType
    );

    switch ($resourceType)
    {
        "appServicePlan" {
            $resourceProvider = "Microsoft.Web"; 
            $resourceProviderExtension = "serverfarms";
            $resourceProviderApiVersion = "2016-09-01";
        }
        "webApp" {
            $resourceProvider = "Microsoft.Web"; 
            $resourceProviderExtension = "sites";
            $resourceProviderApiVersion = "2016-08-01";
            $resourceProviderKind = "app";
        }
        "functionApp" {
            $resourceProvider = "Microsoft.Web"; 
            $resourceProviderExtension = "sites";
            $resourceProviderApiVersion = "2016-08-01";
            $resourceProviderKind = "functionapp";
        }
        "analysisServices" {
            $resourceProvider = "Microsoft.AnalysisServices"; 
            $resourceProviderExtension = "servers";
            $resourceProviderApiVersion = "2017-08-01";
        }
        "appInsights" {
            $resourceProvider = "Microsoft.Insights"; 
            $resourceProviderExtension = "components";
            $resourceProviderApiVersion = "2015-05-01";
        }
        # "^ApiApp$" { $ResourceProviderFilter = { $_.kind -eq "api" } }
        # "^App$" { $ResourceProviderFilter = { $_.kind -eq "app" } }
        # "^StorageAccount$" {
        #     $ResourceProvider = "Microsoft.Storage"; 
        #     $ResourceProviderExtension = "storageAccounts";
        #     $ResourceProviderApiVersion = "2017-06-01"
        # }
        "serviceBus" {
            $ResourceProvider = "Microsoft.ServiceBus"; 
            $ResourceProviderExtension = "namespaces";
            $ResourceProviderApiVersion = "2017-04-01"
        }
        # "^CosmosDBAccount$" {
        #     $ResourceProvider = "Microsoft.DocumentDB"; 
        #     $ResourceProviderExtension = "databaseAccounts";
        #     $ResourceProviderApiVersion = "2015-04-08"
        # }
    }

    @{
        provider           = $resourceProvider;
        providerExtension  = $resourceProviderExtension;
        providerApiVersion = $resourceProviderApiVersion;
        providerKind       = $resourceProviderKind;
    };
}