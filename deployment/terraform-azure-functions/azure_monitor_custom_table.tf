locals {

  custom_table_columns = [
    {
      name = "TimeGenerated"
      type = "DateTime"
    },
    {
      name = "Sku"
      type = "String"
    },
    {
      name = "Region"
      type = "String"
    },
    {
      name = "QuotaAvailable"
      type = "Boolean"
    },
    {
      name = "Score"
      type = "String"
    },
    {
      name = "Subscription"
      type = "String"
    }
  ]
}
# This is an example of how to create a custom table in a Log Analytics Workspace
# This uses the AZAPI provider as of this writing, it is not possible using the AzureRM module
resource "azapi_resource" "lawtable" {
  
  type      = "Microsoft.OperationalInsights/workspaces/tables@2022-10-01"

  # Must have _CL at the end of the table name
  name      = "spot_placement_scores_CL"
  parent_id = azurerm_log_analytics_workspace.law.id
  

  body = {
    properties = {
        schema = {
            name = "spot_placement_scores_CL",
            columns = local.custom_table_columns
    }
    
    }
  }
}