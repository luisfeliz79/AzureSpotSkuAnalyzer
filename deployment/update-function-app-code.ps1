param(
    [string]$subscription,
    [string]$resourceGroupName,
    [string]$functionName
    
)

# This reads configuration from a .env file if parameters are not provided
$resourcePrefix="<NOT USED>"
$location="<NOT USED>"
. ./read-config.ps1

if ($functionName -eq $null -or $functionName -eq "") {
    $functionName = readConfigFile -paramName "FUNCTIONNAME" -Required
}
Write-Host " FunctionName: $functionName" -ForegroundColor Green

pause
az account set --subscription $subscription

Write-host "Deploying Azure Function app code..." -ForegroundColor Green
# Deploy the function code
# Create a zip file of the function app
Compress-Archive -Path ./azure-functions/* -DestinationPath ./azure-functions.zip -Force 


Write-host "Deploying code ..." -ForegroundColor Green
az functionapp deployment source config-zip `
    --name $functionName `
    --resource-group $resourceGroupName `
    --src ./azure-functions.zip

Write-host "Requesting logs ..." -ForegroundColor Green
az functionapp log deployment show --name $functionName --resource-group $resourceGroupName
