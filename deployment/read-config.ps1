function readConfigFile($paramName,[switch]$Required) {

    if (Test-Path ./.env) {
        $envContent = Get-Content ./.env
        foreach ($line in $envContent) {
            if ($line -match "^\s*$paramName\s*=\s*(.+)$") {
                return $matches[1] -replace '"'
            }
        }
        if ($Required) {
            Write-Host "Parameter $paramName not found in the configuration file .env. Either add it to the file or use the -$paramName parameters."
            break
        }
    } else {
        if ($Required) {
            Write-Host "Configuration file .env not found in the current directory. Either create one or use the -subscription, -resourceGroup, and -location parameters."
            break
        }
    }

}

# Deployment configuration
if (($subscription -eq $null) -or ($subscription -eq "")) {
    $subscription = readConfigFile -paramName "SUBSCRIPTION" -Required
}
if (($resourceGroupName -eq $null) -or ($resourceGroupName -eq "")) {
    $resourceGroupName = readConfigFile -paramName "resourceGroupName" -Required
}
if (($location -eq $null) -or ($location -eq "")) {
    $location = readConfigFile -paramName "LOCATION" -Required
}
if ($resourcePrefix -eq $null -or $resourcePrefix -eq "") {
    $resourcePrefix = readConfigFile -paramName "RESOURCEPREFIX"
    if ($resourcePrefix -eq $null -or $resourcePrefix -eq "") {
        $resourcePrefix = "spotscore"
    }
}

Write-Host "Using the following configuration:" -ForegroundColor Green
Write-Host " Subscription:   $subscription" -ForegroundColor Green
Write-Host " resourceGroupName:  $resourceGroupName" -ForegroundColor Green
Write-Host " Location:       $location" -ForegroundColor Green
Write-Host " ResourcePrefix: $resourcePrefix" -ForegroundColor Green


