locals {


  subscription_id              = "<your-subscription-id>"
  resource_group_name          = "<your-resource-group-name>"
  location                     = "<azure-region>"

     # spot_skus - MAX 15 recommended or risk of throttling, comma-separated
  spot_skus    = "Standard_D48as_v4,Standard_D48ds_v4"

     # spot_regions - MAX 5 hard limit, comma-separated
  spot_regions = "eastus2,centralus"

  vnet_address_space              = "10.100.0.0/16"
  subnet_functions_prefix         = "10.100.1.0/24"
  subnet_private_endpoints_prefix = "10.100.2.0/24"

  tags = {
    Environment = "Development"
    Project     = "AzureSpotSkuAnalyzer"
  }

  random_value_suffix          = random_string.suffix.result
  function_app_name            = "spotscore-${local.random_value_suffix}-func"
  storage_account_name         = "spotscoresa${local.random_value_suffix}"
  app_service_plan_name        = "spotscore-${local.random_value_suffix}-plan"
  app_insights_name            = "spotscore-ai"
  log_analytics_workspace_name = "spotscore-law"
  vnet_name                    = "spotscore-vnet"
  dce_name                     = "spotscore-dce"
  dcr_name                     = "spotscore-dcr"

}

# Fetch the primary subscription details
data "azurerm_subscription" "primary" {}

# Create a random string for unique naming
resource "random_string" "suffix" {
  length  = 3
  upper   = false
  lower   = true
  numeric = true
  special = false
}

# Define a resource group
resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = local.location

  tags = local.tags
}
