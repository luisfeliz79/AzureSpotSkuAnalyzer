## Deployment using Terraform

### Access Requirements
On the subscription: 
   - Owner (Due to configuration of RBAC permissions)<br>
                --or--
   - Contributor + User Access Administrator


## PART 1 - Deploy the solution's infrastructure

1. Clone the repository
    ```bash
    git clone https://github.com/luisfeliz79/AzureSpotSkuAnalyzer.git
    ```
2. Navigate to the cloned directory, deployment directory.
   ```bash
   cd ./AzureSpotSkuAnalyzer/deployment/terraform-azure-functions
   ```

3. Modify the [`main.tf`](./main.tf) file to set your desired parameters, such as:
   - `subscription_id`
   - `resource_group_name`
   - `location`
   - `spot_skus` (comma-separated list of SKUs)
   - `spot_regions` (comma-separated list of regions)

4. Run the deployment script using the following command:
   ```bash
   
   # Authenticate to Azure if needed
   az login --tenant "<your-tenant-id>"

   terraform init
   terraform plan -out=my.plan
   terraform apply "my.plan"
   ```

## PART 2 - Deploy the Azure Functions code
```bash
   az functionapp deployment source config-zip \
      --name "<func-name>" \
      --resource-group "<resource-group-name>" \
      --src ../functions-source.zip

```

## Clean up
To delete the resources created by this deployment, you can use the following command:
```bash
   terraform destroy --auto-approve
```
