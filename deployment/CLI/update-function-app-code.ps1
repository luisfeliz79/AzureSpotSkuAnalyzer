param(
    [string]$subscription,
    [string]$resourceGroupName,
    [string]$functionName,
    [switch]$RequestLogs
    
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
Compress-Archive -Path ../azure-functions/functions-source/* -DestinationPath ./functions-source.zip -Force 


Write-host "Deploying code ..." -ForegroundColor Green
    Write-host "You may see timeout issues, however the deployment should complete successfully" -ForegroundColor Yellow
    Write-host "You may retry by running the following command if needed:" -ForegroundColor Yellow
    Write-host "./update-function-app-code.ps1 -subscription '$subscription' -resourceGroupName '$resourceGroupName' -functionName '$functionName'" -ForegroundColor Yellow

    az functionapp deployment source config-zip `
    --name $functionName `
    --resource-group $resourceGroupName `
    --src ./functions-source.zip
    
if ($RequestLogs) {
    Write-host "Waiting 30 seconds for the deployment to complete ..." -ForegroundColor Green
    Start-Sleep -Seconds 30
    Write-host "Requesting logs ..." -ForegroundColor Green
    az functionapp log deployment show --name $functionName --resource-group $resourceGroupName
}
