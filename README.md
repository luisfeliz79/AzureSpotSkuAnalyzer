# Spot Placement Score analysis tool
### By Luis Feliz

This tool helps visualize Azure Spot Placement Scores for virtual machine SKUs across different regions.

It leverages the [Azure Spot Placement Score API](https://learn.microsoft.com/en-us/azure/virtual-machine-scale-sets/spot-placement-score?tabs=portal) to gather data and present it in an Azure Workbook for easy analysis.

> Note: Spot placement scores serve purely as a recommendation based on certain data points like Spot VM availability. A high placement score doesn't guarantee that the Spot request will be fully or partially fulfilled. Placement Scores are only valid at the time when it's requested. The same Placement Score isn't valid at a different time of the same day or another day. Any similarities are purely coincidental. As such, using this tool for predictive analysis is not recommended.


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


## For examples on how to use the Spot Placement Score API directly via command line, [see here](./examples/CLI/README.md).