# Azure Spot Placement Score API - CLI Examples

## Bash Example

```bash
requestLocation="eastus2"
requestSubscription="fc4f8971-77b0-47e6-a975-e183b16794cb"
desiredCount=10
desiredLocations="eastus2"
desiredSizes='[{"sku":"Standard_D2_v2"},{"sku":"Standard_D4_v2"}]'

az compute-recommender spot-placement-recommender --location $requestLocation --subscription $requestSubscription --desired-locations $desiredLocations --desired-count $desiredCount  --desired-sizes $desiredSizes
```


## PowerShell example (when using Azure CLI)

```powershell
$requestLocation="eastus2"
$requestSubscription="fc4f8971-77b0-47e6-a975-e183b16794cb"
$desiredCount=10
$desiredLocations="eastus2"
$desiredSizesList="Standard_D96ds_v5, Standard_D16_v5, Standard_D64_v5, Standard_D96_v5, Standard_D16s_v5"
$desiredSizesTmp=$desiredSizesList -replace ' ','' -split ','
$desiredSizesObj=$desiredSizesTmp|ForEach-Object { [PSCustomObject]@{ sku = $_ } }
$desiredSizes=$desiredSizesObj|ForEach-Object { [PSCustomObject]@{ sku = $_ } }|ConvertTo-Json -Compress

az compute-recommender spot-placement-recommender --location $requestLocation --subscription $requestSubscription --desired-locations $desiredLocations --desired-count $desiredCount  --desired-sizes $desiredSizes


# ---- or ----

$desiredSizes=@()
$desiredSizesTmp | ForEach-Object {
            $desiredSizes+= @{sku = $_}
        }
        
$results=Invoke-AzSpotPlacementRecommender -Location $requestLocation -SubscriptionId $requestSubscription -DesiredCount $desiredCount -DesiredLocation $desiredLocations -DesiredSize $desiredSizes

$results