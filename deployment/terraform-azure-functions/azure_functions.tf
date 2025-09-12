# Create an App Service Plan

resource "azurerm_service_plan" "plan1" {
  name                = "${local.function_app_name}-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "S1"

  tags = local.tags

}

resource "azurerm_linux_function_app" "funcapp" {
  name                 = local.function_app_name
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  storage_account_name = azurerm_storage_account.sa.name
  service_plan_id      = azurerm_service_plan.plan1.id

  //vnet integration
  virtual_network_subnet_id = azurerm_subnet.azure-functions.id


  //Security  
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false
  storage_uses_managed_identity                  = true
  https_only                                     = true


  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.function_app_identity.id]
  }

  tags = {
    "hidden-link: /app-insights-resource-id" = azurerm_application_insights.ai.id
  }

  site_config {

    application_insights_connection_string = azurerm_application_insights.ai.connection_string

    always_on = true

    cors {
      allowed_origins = ["https://portal.azure.com"]
    }

    ftps_state                  = "Disabled"
    scm_use_main_ip_restriction = true
    vnet_route_all_enabled      = true

    application_stack {
      powershell_core_version = 7.4
    }
  }

  app_settings = {

    # Solution environment variables
    AZURE_CLIENT_ID          = azurerm_user_assigned_identity.function_app_identity.client_id
    MONITOR_ENDPOINT_URI     = azurerm_monitor_data_collection_endpoint.dce.logs_ingestion_endpoint
    MONITOR_DCR_IMMUTABLE_ID = azurerm_monitor_data_collection_rule.dcr.immutable_id
    SPOT_SKUS                = local.spot_skus
    SPOT_REGIONS             = local.spot_regions

    # Azure Functions host storage settings
    AzureWebJobsStorage__blobServiceUri = azurerm_storage_account.sa.primary_blob_endpoint
    AzureWebJobsStorage__credential     = "managedidentity"
    AzureWebJobsStorage__clientId       = azurerm_user_assigned_identity.function_app_identity.client_id

    # Azure functions settings
    SCM_DO_BUILD_DURING_DEPLOYMENT = "false"
    FUNCTIONS_WORKER_RUNTIME       = "powershell"
    #WEBSITE_RUN_FROM_PACKAGE = "1"
    #APPLICATIONINSIGHTS_AUTHENTICATION_STRING = "Authorization=AAD"

  }

  # Azure Functions populates some tags directly that
  # could conflict with terraform, ignore the tags
  lifecycle {
    ignore_changes = [tags]
  }

}

module "func-diagnostics" {
  source                     = "./modules/diagnostics"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  target_resource_id         = azurerm_linux_function_app.funcapp.id
}

