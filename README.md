# Spot Placement Score analysis tool
### By Luis Feliz

This tool analyzes Azure Spot Placement Scores for virtual machine SKUs across different regions.

### See which SKUs score high the most
![Azure Spot Placement Score Analysis Tool](./images/high-scoring-skus.png)

### Analyze the list of Skus, eviction rates, price, and score history
![Sku Analysis Grid](./images/sku-analysis-grid.png)

## Deployment

### Requirements
- Access
On the subscription or pre-created resource group:
   - Owner (Due to configuration of RBAC permissions)<br>
                --or--
   - Contributor + User Access Administrator
- Tools
   - Azure CLI
   - PowerShell
   - If using Azure Shell, select Linux Bash, and then enter powershell mode using "pwsh"

## Deployed resources
This script deploys the following required resources:
- Azure Function App and App Service plan
- Azure Storage Account
- Azure Log Analytics workspace
- Azure Application Insights
- Data Collection endpoints and Rules
- Virtual network, subnets, and private endpoints and zones
- RBAC settings for the Storage account, and Data Collection Rule
- Azure Workbook
- Function Script code

## To deploy the solution
1. Open a PowerShell terminal or [Azure Cloud Shell](https://shell.azure.com).  If using Cloud Shell, you can select PowerShell or Bash (then run pwsh)
2. Clone the repository
    ```bash
    git clone https://github.com/luisfeliz79/AzureSpotSkuAnalyzer.git
    ```
2. Navigate to the cloned directory, deployment directory.
   ```bash
   cd ./AzureSpotSkuAnalyzer/deployment
   ```
3. Update `$subscription`,`$resourceGroupName`,`$skus` and `$regions` as needed in [deploy-solution.ps1](./deployment/deploy-solution.ps1)
4. Run the deployment script using the following command:
   ```bash   
   # bash
   pwsh ./deploy-solution.ps1
   
   # powershell
   ./deploy-solution.ps1
   ```

## To update the SKUs and regions
### Limits
- The maximum number of recommended SKUs is 15 to avoid throttling
- The maximum number of regions that can be analyzed is 5
### Steps
1. Open the [update-skus-and-regions.ps1](./deployment/update-skus-and-regions.ps1) script
2. Update `$subscription`,`$resourceGroupName`, `$functionName`, `$skus` and `$regions` as needed
3. Run the script using the following command:
   ```bash
   cd ./AzureSpotSkuAnalyzer/deployment

   # bash
   pwsh ./update-skus-and-regions.ps1

   # powershell
   ./update-skus-and-regions.ps1
   ```

## Clean up
To delete the resources created by this deployment, you can use the following command:
```bash
az group delete --name "<resource-group-name>" --yes --no-wait
```
