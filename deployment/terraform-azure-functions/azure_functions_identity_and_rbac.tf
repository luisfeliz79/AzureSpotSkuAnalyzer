# Create a User assigned managed identity
resource "azurerm_user_assigned_identity" "function_app_identity" {
  name                = "${local.function_app_name}-identity"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  tags = local.tags
}

# RBAC for Storage Account access
resource "azurerm_role_assignment" "access-to-sa" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.function_app_identity.principal_id
}

#RBAC for Log Ingestion via DCR
resource "azurerm_role_assignment" "access-to-dcr" {
  scope                = azurerm_monitor_data_collection_rule.dcr.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = azurerm_user_assigned_identity.function_app_identity.principal_id
}


# Custom Role for Spot Placement Score API access
resource "azurerm_role_definition" "custom-spot-api-role" {
  name        = "Spot Placement Score API access"
  scope       = data.azurerm_subscription.primary.id
  description = "This role provides access to the Spot Placement Score API in a subscription"

  permissions {
    actions     = ["Microsoft.Compute/locations/placementScores/generate/action"]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.primary.id
  ]
}

#RBAC For Subscription management
resource "azurerm_role_assignment" "subscription-spot-api-access" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = azurerm_role_definition.custom-spot-api-role.name
  principal_id         = azurerm_user_assigned_identity.function_app_identity.principal_id

  depends_on = [azurerm_role_definition.custom-spot-api-role]
}
