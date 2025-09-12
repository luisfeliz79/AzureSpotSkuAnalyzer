# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = local.log_analytics_workspace_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"

  tags = local.tags
}
# Application Insights for Azure Functions logging
resource "azurerm_application_insights" "ai" {
  name                = local.app_insights_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "web"

  local_authentication_disabled = false
  # Azure Functions does not support Entra ID auth to App Insights as of 4/2/2024
  # https://learn.microsoft.com/en-us/azure/azure-monitor/app/azure-ad-authentication?tabs=net#unsupported-scenarios

  tags = local.tags
}

# Data Collection Endpoint for solution log ingestion
resource "azurerm_monitor_data_collection_endpoint" "dce" {
  name                          = local.dce_name
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  tags                          = local.tags
  public_network_access_enabled = true
  description                   = "Used for sending data to Log Analytics Workspace"

  
}

# Data Collection Rule for solution log ingestion
resource "azurerm_monitor_data_collection_rule" "dcr" {
  name                          = local.dcr_name
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  data_collection_endpoint_id   = azurerm_monitor_data_collection_endpoint.dce.id
  
    # Which Log Analytics workspace to send data to
    destinations {
      log_analytics {
        workspace_resource_id = azurerm_log_analytics_workspace.law.id
        name                  = azurerm_log_analytics_workspace.law.name
      }
    }

    stream_declaration  {
          stream_name = "Custom-spot_placement_scores_CL"

        dynamic "column" {
          iterator = each
          for_each = local.custom_table_columns
          content {
            name = each.value.name
            type = lower(each.value.type)
          }
          
        }
          
        }
  

   

    # Data_flow blocks define which streams to send to which destinations

    data_flow {
      streams      = ["Custom-spot_placement_scores_CL"]
      destinations = [azurerm_log_analytics_workspace.law.name]
      output_stream = "Custom-spot_placement_scores_CL"
    }


    description = "DCR for custom ingestion of Spot Placement Scores data"

  depends_on = [ azapi_resource.lawtable,azurerm_monitor_data_collection_endpoint.dce ]
  
  tags = local.tags
}

# Generate a random system name for the workbook
resource "random_uuid" "workbook" {
}

# Azure Monitor Workbook for solution visualization
resource "azurerm_application_insights_workbook" "spotworkbook" {
  name                = random_uuid.workbook.result
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  display_name        = "Spot Placement Score Analysis"
  data_json = jsonencode(templatefile("../workbooks/workbook-terraform-template.json", {
    TFWorkspaceId = azurerm_log_analytics_workspace.law.id
  }))

  tags = local.tags
}


