## Deployment using Powershell + Azure CLI

### Access Requirements
On the subscription or pre-created resource group:
   - Owner (Due to configuration of RBAC permissions)<br>
                --or--
   - Contributor + User Access Administrator


## To deploy the solution

1. Clone the repository
    ```powershell
    git clone https://github.com/luisfeliz79/AzureSpotSkuAnalyzer.git
    ```
2. Navigate to the cloned directory, deployment directory.
   ```powershell
   cd ./AzureSpotSkuAnalyzer/deployment/CLI
   ```
4. Run the deployment script using the following command:
   ```powershell   
   # Authenticate to Azure if needed
   az login --tenant "<your-tenant-id>"

   # Deploy the Azure functions based solution
   ./deploy-azure-functions-solution.ps1 `
      -subscription "<your-subscription-id>" `
      -resourceGroupName "<your-resource-group-name>" `
      -location "<azure-region>"

   # In Bash, prefix it with pwsh
   pwsh ./deploy-azure-functions-solution.ps1 `
      -subscription "<your-subscription-id>" `
      -resourceGroupName "<your-resource-group-name>" `
      -location "<azure-region>"
   ```

## To update the SKUs and regions
### Limits
- The maximum number of recommended SKUs is 15 to avoid throttling
- The maximum number of regions that can be analyzed is 5
### Steps
1.  Navigate to the cloned directory, deployment directory.
      ```powershell
      cd ./AzureSpotSkuAnalyzer/deployment/CLI
      ```
2. Run the deployment script using the following command:
   ```powershell
   
   # Authenticate to Azure if needed
   az login --tenant "<your-tenant-id>"

   # powershell
   ./update-function-app-skus-and-regions.ps1 `
   -subscription "<your-subscription-id>" `
   -resourceGroupName "<your-resource-group-name>" `
   -functionName "<your-function-app-name>" `
   -Spot_Regions "eastus2,centralus" `
   -Spot_SKUs "Standard_D48as_v4,Standard_D48ds_v4"

   # In Bash, prefix it with pwsh
   pwsh ./update-function-app-skus-and-regions.ps1 `
   -subscription "<your-subscription-id>" `
   -resourceGroupName "<your-resource-group-name>" `
   -functionName "<your-function-app-name>" `
   -Spot_Regions "eastus2,centralus" `
   -Spot_SKUs "Standard_D48as_v4,Standard_D48ds_v4"
   
   ```

## Clean up
To delete the resources created by this deployment, you can use the following command:
```bash
   az group delete --name "<resource-group-name>" --yes --no-wait
```
