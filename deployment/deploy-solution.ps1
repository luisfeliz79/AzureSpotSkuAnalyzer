#########################################################
#  Spot Placement Score analysis tool
#########################################################
# This script deploys the following resources:
#   Azure Function App and App Service plan
#   Azure Storage Account
#   Azure Log Analytics workspace
#   Azure Application Insights
#   Data Collection endpoints and Rules
#   Virtual network and subnets
#   RBAC settings for the Storage account, and Data Collection Rule
#
# Permissions required on a subscription or Resource Group:
#   Owner (Due to needed RBAC permissions)
#                --or--
#   Contributor + User Access Management
#
# Required tools
#   Azure CLI
#   PowerShell
# If using Azure Shell, select Linux Bash, and then enter "pwsh ./deploy-solution.ps1" 

# Deployment configuration
$subscription           = "<subscription-name>"
$resourceGroupName      = "<resource-group>"

$resourcePrefix         = "spotscore"
$location               = "eastus2"


# Initial configuration
# Define the SKU list here
$ListOFSkus = @(
    "Standard_D48as_v4",
    "Standard_D48ds_v4",    
    "Standard_D48ads_v5",    
    "Standard_E48as_v4",
    "Standard_E48ds_v4",
    "Standard_E48ads_v5",
    "Standard_E48as_v5",
    "Standard_D48as_v6",
    "Standard_D96as_v5"
)

# Define the region list here
$ListOfRegions = @(
    "eastus2",
    "centralus",
    "eastus"
)

#### Calculated variables
if (Test-Path "./tmp-spot-install-random-value.txt") {
    $RANDOM = Get-Content "./tmp-spot-install-random-value.txt"
} else {
    $RANDOM = ([System.Guid]::NewGuid().ToString() -split '-')[1]
    $RANDOM | out-file "./tmp-spot-install-random-value.txt"
}
Write-host "Using random value: $RANDOM" -ForegroundColor Cyan
$virtualNetworkName   = "$resourcePrefix-vnet"
$functionName         = "$($resourcePrefix)-$($RANDOM)-func"
$planName             = "$($resourcePrefix)-plan"
$STORAGE_ACCOUNT_NAME = "$($resourcePrefix)$($RANDOM)sa"
$LOG_ANALYTICS_NAME   = "$($resourcePrefix)$($RANDOM)law"
$APP_INSIGHTS_NAME    = "$($resourcePrefix)$($RANDOM)ai"
$DCE_NAME             = "$($resourcePrefix)-dce"
$DCR_NAME             = "$($resourcePrefix)-dcr"
$address_prefix_octects = "10.0"
$TableName            = "spot_placement_scores" # Do not modify

try {

    Write-host "Pre-installing needed extensions..."
    az extension add --name monitor-control-service --allow-preview=true
    az extension add --name application-insights --allow-preview=true

    az account set --subscription $subscription

    Write-Host "Creating resource group..." -ForegroundColor Green
    az group create --name $resourceGroupName --location $location

    Write-Host "Creating Virtual Network..." -ForegroundColor Green
    #Create a Virtual Network
    $virtualNetworkName = "$resourcePrefix-vnet"
    $addressPrefix = "$($address_prefix_octects).0.0/16"
    az network vnet create --name $virtualNetworkName `
        --resource-group $resourceGroupName `
        --address-prefix $addressPrefix

    Write-Host "Creating subnets..." -ForegroundColor Green
    # Add subnets
    $subnet1Name = "functions"
    $subnet1Prefix = "$($address_prefix_octects).0.0/24"
    az network vnet subnet create --name $subnet1Name `
        --resource-group $resourceGroupName `
        --vnet-name $virtualNetworkName `
        --address-prefix $subnet1Prefix

    $subnet2Name = "endpoint"
    $subnet2Prefix = "$($address_prefix_octects).1.0/24"
    az network vnet subnet create --name $subnet2Name `
        --resource-group $resourceGroupName `
        --vnet-name $virtualNetworkName `
        --address-prefix $subnet2Prefix

    # Create Storage account using Azure CLI
    $Storage_SKU="Standard_LRS"
    $Storage_KIND="StorageV2"

    Write-host "Creating Storage account..." -ForegroundColor Green
    az storage account create `
    --name $STORAGE_ACCOUNT_NAME `
    --resource-group $resourceGroupName `
    --location $Location `
    --sku $Storage_SKU `
    --kind $Storage_KIND `
    --min-tls-version TLS1_2 `
    --allow-shared-key-access false `
    --public-network-access disabled

    Write-host "Configurating Private endpoints..." -ForegroundColor Green
    Write-host " - Zone" -ForegroundColor Green
    # Configure Private Link
    # Create the Private DNS Zone
    az network private-dns zone create `
    --resource-group $resourceGroupName `
    --name privatelink.blob.core.windows.net
    Write-host " - Waiting 15 seconds" -ForegroundColor Green
    Start-Sleep -Seconds 15

    Write-host " - VNET Link" -ForegroundColor Green

    # Link the Private DNS Zone
    az network private-dns link vnet create `
        --resource-group $resourceGroupName  `
        --zone-name privatelink.blob.core.windows.net `
        --name $virtualNetworkName `
        --virtual-network $virtualNetworkName `
        --registration-enabled true

    Write-host " - Endpoint" -ForegroundColor Green
    # Create the Private Endpoint
    $saId = $(az storage account show --name $STORAGE_ACCOUNT_NAME --query id --output tsv)
    az network private-endpoint create `
        --name blobpe `
        --resource-group $resourceGroupName `
        --vnet-name $virtualNetworkName `
        --subnet $subnet2Name `
        --private-connection-resource-id $saId `
        --group-id blob `
        --connection-name blobpe 

    Write-host " - Private Endpoint+Zone integration" -ForegroundColor Green

    # Integrate Private endpoint with DNS Zone
    az network private-endpoint dns-zone-group create `
        --resource-group $resourceGroupName `
        --endpoint-name blobpe `
        --name blob `
        --zone-name privatelink.blob.core.windows.net `
        --private-dns-zone privatelink.blob.core.windows.net

    Write-host "Creating Log Analytics workspace..." -ForegroundColor Green
    # Create the Log Analytics workspace
    az monitor log-analytics workspace create `
    --resource-group $resourceGroupName `
    --workspace-name $LOG_ANALYTICS_NAME `
    --location $location


    Write-host "Creating Application Insights instance..." -ForegroundColor Green


    # Create the Application Insights instance
    az monitor app-insights component create `
    --app $APP_INSIGHTS_NAME `
    --location $location `
    --resource-group $resourceGroupName `
    --application-type web `
    --workspace $LOG_ANALYTICS_NAME

    Write-host "Creating App Service plan..." -ForegroundColor Green
    # Create an App service plan
    az appservice plan create `
        --name $planName `
        --resource-group $resourceGroupName `
        --location $location `
        --sku S1 `
        --is-linux

    Write-host "Creating Function App..." -ForegroundColor Green
    # Create an Azure Function App
    az functionapp create `
        --storage-account $STORAGE_ACCOUNT_NAME `
        --resource-group $resourceGroupName `
        --plan $planName `
        --assign-identity '[system]' `
        --app-insights $APP_INSIGHTS_NAME `
        --runtime-version "7.4" `
        --runtime powershell `
        --vnet $virtualNetworkName `
        --subnet $subnet1Name `
        --name $functionName `
        --os-type Linux

    Write-host "Configuring Azure Functions Always on..." -ForegroundColor Green
    az functionapp config set --always-on true --name $functionName --resource-group $resourceGroupName
    
    Write-host "Configuring Azure Functions VNET ROUTE ALL..." -ForegroundColor Green
    az resource update --resource-group $resourceGroupName --name $functionName  --resource-type "Microsoft.Web/sites" --set properties.vnetRouteAllEnabled=true --api-version "2022-03-01"
    
    Write-host "Configuring Azure Functions Host Storage with Managed Identity..." -ForegroundColor Green

    # Configure Host storage with Managed Identity
    # Configure RBAC
    $functionPrincipalId=$(az functionapp identity show --name $functionName --resource-group $resourceGroupName --query principalId --output tsv)
    az role assignment create --assignee $functionPrincipalId --role "Storage Blob Data Contributor" --scope $saId

    # Set Function App settings for host storage
    az functionapp config appsettings set --name $functionName --resource-group $resourceGroupName --settings "AzureWebJobsStorage__blobServiceUri=https://$($STORAGE_ACCOUNT_NAME).blob.core.windows.net/"
    az functionapp config appsettings set --name $functionName --resource-group $resourceGroupName --settings "SCM_DO_BUILD_DURING_DEPLOYMENT=false"
    
    Write-host "Azure Functions Clean up unneeded settings..." -ForegroundColor Green
    # Clean up unnecessary settings
    az functionapp config appsettings delete --name $functionName --resource-group $resourceGroupName --setting-names "AzureWebJobsStorage","WEBSITES_ENABLE_APP_SERVICE_STORAGE"
    
    Write-host "Azure Functions Configuring CORS..." -ForegroundColor Green
    # Configure CORS
    az functionapp cors add --name $functionName --resource-group $resourceGroupName --allowed-origins "https://portal.azure.com"

    Write-host "Azure Log Ananalytics Workspace Custom table..." -ForegroundColor Green
    $WORKSPACE_RESOURCE_ID=az monitor log-analytics workspace show --name $LOG_ANALYTICS_NAME --resource-group $resourceGroupName --query id --output tsv

    # Tablename should not include _CL, as it is added by the script
    if ($TableName -match "_CL") {
        $TableName = $TableName -replace '_CL'
    }

    # Create a powershell object instead then convert to JSON
    $tableParams = [PSCustomObject]@{
        properties = @{
            schema = @{
                name = "$($TableName)_CL"
                columns = @(
                    @{ name = "TimeGenerated"; type = "datetime"; description = "The time at which the data was ingested." },
                    @{ name = "Sku"; type = "string"; description = "The SPOT SKU" },
                    @{ name = "Region"; type = "string"; description = "Region" },
                    @{ name = "QuotaAvailable"; type = "boolean"; description = "Is there quota for this SKU in the subscription" },
                    @{ name = "Score"; type = "string"; description = "The placement score - Low, Medium or High" },
                    @{ name = "Subscription"; type = "string"; description = "The Subscription for the request" }
            
                )
            }
        }
    } | ConvertTo-Json -Depth 10

    Invoke-AzRestMethod -Path "$WORKSPACE_RESOURCE_ID/tables/$($TableName)_CL?api-version=2021-12-01-preview" -Method PUT -payload $tableParams



    Write-host "Azure Monitor Data Collection Rule and Data Collection Endpoint..." -ForegroundColor Green

    # Configure the DCR and DCE
    az monitor data-collection endpoint create `
        --resource-group $resourceGroupName --name $DCE_NAME `
        --location $location `
        --public-network-access enabled

    $DCE_ID = $(az monitor data-collection endpoint show --resource-group $resourceGroupName --name $DCE_NAME --query id --output tsv)

    # Create the Custom Table at this point so it is available when the function runs
    $TableSchema=$(az monitor log-analytics workspace table show --name "$($TableName)_CL" --resource-group $resourceGroupName --workspace-name $LOG_ANALYTICS_NAME --query schema.columns)|convertFrom-json
    $TableSchemaNameAndType=@()
    $TableSchema | Foreach-Object { 
        $TableSchemaNameAndType+=[PSCustomObject](@{ 
            name=$_.name
            type=$_.type
        })
    }

    $StreamDeclaration=@{
        
                "Custom-$($TableName)_CL" = @{ "columns"=@()}
        
    } | ConvertTo-Json -Depth 3 -compress
    $StreamDeclaration=$StreamDeclaration -replace '\[\]',"$($TableSchemaNameAndType | convertTo-Json -Depth 3 -Compress)"
    $StreamDeclaration

    $DataFlows = [PsCustomObject]@{
            streams = @("Custom-$($TableName)_CL")
            destinations = @($LOG_ANALYTICS_NAME)
            outputStream = "Custom-$($TableName)_CL"
        }

    $DataFlows="["+$($DataFlows | ConvertTo-Json -Depth 10 -Compress)+"]"
    $DataFlows

    $Destinations = [PsCustomObject]@{
            logAnalytics = @(
                @{
                    workspaceResourceId = $WORKSPACE_RESOURCE_ID
                    name = $LOG_ANALYTICS_NAME
                }
            )
        }
    $Destinations=$Destinations | ConvertTo-Json -Depth 10 -Compress
    $Destinations

    # Create an Azure Monitor Data Collection Rule
    az monitor data-collection rule create `
        --resource-group $resourceGroupName `
        --name $DCR_NAME `
        --stream-declarations $StreamDeclaration `
        --data-flows $DataFlows `
        --destinations $Destinations `
        --endpoint-id $DCE_ID `
        --location $location

    Write-host "RBAC: Assigning Monitoring Metrics Publisher to the DCR..." -ForegroundColor Green
    # Give the function app's managed identity access to the DCR
    $DCR_ID = $(az monitor data-collection rule show --resource-group $resourceGroupName --name $DCR_NAME --query id --output tsv)
    az role assignment create --assignee $functionPrincipalId --role "Monitoring Metrics Publisher" --scope $DCR_ID

    # Get Azure Monitor rule and endpoint information
    $DCE_LOG_INGESTION_URI=$(az monitor data-collection endpoint show --resource-group $resourceGroupName --name $DCE_NAME --query logsIngestion.endpoint --output tsv)
    $DCR_IMMUTABLE_ID=$(az monitor data-collection rule show --resource-group $resourceGroupName --name $DCR_NAME --query immutableId --output tsv)

    Write-host "Configuring Azure Monitor details as Environment Variables..." -ForegroundColor Green
    # Set Function App needed settings
    az functionapp config appsettings set --name $functionName --resource-group $resourceGroupName --settings "MONITOR_ENDPOINT_URI=$DCE_LOG_INGESTION_URI"
    az functionapp config appsettings set --name $functionName --resource-group $resourceGroupName --settings "MONITOR_DCR_IMMUTABLE_ID=$DCR_IMMUTABLE_ID"


    Write-host "Configuring SKU details as Environment Variables..." -ForegroundColor Green

    $Spot_SKUs = $ListOFSkus -join ","
    $Spot_Regions = $ListOfRegions -join ","

    az functionapp config appsettings set --name $functionName --resource-group $resourceGroupName --settings "SPOT_SKUS=$Spot_SKUs"
    az functionapp config appsettings set --name $functionName --resource-group $resourceGroupName --settings "SPOT_REGIONS=$Spot_Regions"

    Write-host "Deploying Azure Function app code..." -ForegroundColor Green
    # Deploy the function code
    # Create a zip file of the function app
    Compress-Archive -Path ./azure-functions/* -DestinationPath ./azure-functions.zip -Force 

    az functionapp deployment source config-zip `
        --name $functionName `
        --resource-group $resourceGroupName `
        --src ./azure-functions.zip

    az functionapp log deployment show --name $functionName --resource-group $resourceGroupName


    Write-host "Deploying Workbook..."
    # Deploy an Azure Workbook Arm template
    az deployment group create `
        --resource-group $resourceGroupName `
        --template-file ./workbooks/workbook-arm-template.json 

    Write-host "Deployment completed!" -ForegroundColor Green

    Write-host "NOTE: Always on is required for proper function of this solution" -ForegroundColor Yellow
    Write-host "If telemetry stops, please check the function app settings and ensure that the Always On setting is enabled." -ForegroundColor Yellow
}

catch {
    Write-Host "Error occurred during deployment: $_" -ForegroundColor Red
}