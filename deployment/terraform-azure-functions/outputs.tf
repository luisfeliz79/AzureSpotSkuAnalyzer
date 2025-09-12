output "FUNCTION_APP_NAME" {
  value = azurerm_linux_function_app.funcapp.name
}

output "USER_ASSIGNED_MANAGED_IDENTITY_NAME" {
  value = azurerm_user_assigned_identity.function_app_identity.name
}

output "WORKBOOK_DISPLAY_NAME" {
  value = azurerm_application_insights_workbook.spotworkbook.display_name
}

output "LOG_ANALYTICS_WORKSPACE_NAME" {
  value = azurerm_log_analytics_workspace.law.name
}

output "DEPLOYMENT_ENDPOINT" {
  value = "https://${azurerm_linux_function_app.funcapp.name}.scm.azurewebsites.net"
}

output "DEPLOYMENT_CODE_PUSH_COMMAND" {
  value = "az functionapp deployment source config-zip --name ${azurerm_linux_function_app.funcapp.name} --resource-group ${azurerm_resource_group.rg.name} --src ../functions-source.zip"
}