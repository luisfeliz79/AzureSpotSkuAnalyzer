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
1. Clone the repository
2. Open a terminal and navigate to the cloned directory
3. Update `$subscription`,`$resourceGroupName`,`$skus` and `$regions` as needed in [deploy-solution.ps1](./deployment/deploy-solution.ps1)
4. Run the deployment script using the following command:
   ```bash
   cd deployment
   pwsh ./deploy-solution.ps1
   ```

## To update the SKUs and regions
1. Open the [update-skus-and-regions.ps1](./deployment/update-skus-and-regions.ps1) script
2. Update `$subscription`,`$resourceGroupName`,`$skus` and `$regions` as needed
3. Run the script using the following command:
   ```bash
   cd deployment
   pwsh ./update-skus-and-regions.ps1
   ```
