# Use this script to update the list of SKUs and regions
# you would like to track

param(
    [string]$subscription,
    [string]$resourceGroup,
    [string]$functionName,
    [string]$resourcePrefix="<NOT USED>",
    [string]$Spot_SKUs,
    [string]$Spot_Regions
)

# This reads configuration from a .env file if parameters are not provided
$resourcePrefix="<NOT USED>"
$location="<NOT USED>"
. ./read-config.ps1

if ($functionName -eq $null -or $functionName -eq "") {
    $functionName = readConfigFile -paramName "FUNCTIONNAME" -Required
}
Write-Host " FunctionName: $functionName" -ForegroundColor Green

if ($Spot_SKUs -eq $null -or $Spot_SKUs -eq "") {
    $Spot_SKUs = readConfigFile -paramName "SPOT_SKUS" -Required
}
if ($Spot_Regions -eq $null -or $Spot_Regions -eq "") {
    $Spot_Regions = readConfigFile -paramName "SPOT_REGIONS" -Required
}
$Spot_SKUs = $Spot_SKUs -replace '\s',''
$Spot_Regions = $Spot_Regions -replace '\s',''

Write-Host " Spot_SKUs: $Spot_SKUs" -ForegroundColor Green
Write-Host " Spot_Regions: $Spot_Regions" -ForegroundColor Green

pause
# Update the functions app
az account set --subscription $subscription
az functionapp config appsettings set --name $functionName --resource-group $resourceGroupName --settings "SPOT_SKUS=$Spot_SKUs"
az functionapp config appsettings set --name $functionName --resource-group $resourceGroupName --settings "SPOT_REGIONS=$Spot_Regions"


