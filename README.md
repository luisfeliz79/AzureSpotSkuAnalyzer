# Spot Placement Score analysis tool
### By Luis Feliz

This tool analyzes Azure Spot Placement Scores for virtual machine SKUs across different regions.

### See which SKUs score high the most
![Azure Spot Placement Score Analysis Tool](./images/high-scoring-skus.png)

### Analyze the list of Skus, eviction rates, price, and score history
![Sku Analysis Grid](./images/sku-analysis-grid.png)

## Deployment

### Access Requirements for deployment
On the subscription or pre-created resource group:
   - Owner (Due to configuration of RBAC permissions, and custom role)<br>
                --or--
   - Contributor + User Access Administrator


## Deployed resources
This script deploys the following required resources:
- Azure Function App and App Service plan
- Azure Storage Account
- Azure Log Analytics workspace
- Azure Application Insights
- Data Collection endpoints and Rules
- Virtual network, subnets, and private endpoints and zones
- Azure Workbook
- RBAC settings for the Storage account, and Data Collection Rule
- Custom Role for Least Privilege access to Spot Placement Scores
- For internal employees: This solution is SFI compliant

## Deployment options
- [Deploy using Terraform](./deployment/terraform-azure-functions/README.md)
- [Deploy using CLI](./deployment/CLI/README.md)