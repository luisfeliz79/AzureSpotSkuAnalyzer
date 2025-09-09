# Use this script to update the list of SKUs and regions
# you would like to track

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

# Azure Functions information
$subscription           = "<subscription-name>"
$resourceGroupName      = "<resource-group>"
$resourcePrefix         = "spotscore"
$functionName           = "$($resourcePrefix)-func"

# Calculated Variables
$Spot_SKUs = $ListOFSkus -join ","
$Spot_Regions = $ListOfRegions -join ","

# Update the functions app
az account set --subscription $subscription
az functionapp config.appsettings set --name $functionName --resource-group $resourceGroupName --settings "SPOT_SKUS=$Spot_SKUs"
az functionapp config.appsettings set --name $functionName --resource-group $resourceGroupName --settings "SPOT_REGIONS=$Spot_Regions"


