
# Deploy a Storage account
resource "azurerm_storage_account" "sa" {
  name                       = local.storage_account_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name

  account_tier              = "Standard"
  account_kind              = "StorageV2"
  account_replication_type  = "LRS"
  https_traffic_only_enabled = true
  min_tls_version           = "TLS1_2"

  shared_access_key_enabled = false

  public_network_access_enabled = false

  identity {
    type = "SystemAssigned"
  }

  network_rules {
    default_action = "Deny"
    ip_rules = []    
  }

  lifecycle {
    ignore_changes = [ customer_managed_key, network_rules,allow_nested_items_to_be_public ]
  }


  tags = local.tags
}

# Private Endpoints setup
##### ASSUMPTIONS #################################################
# The Private DNS Zone for blob.core.windows.net already exists   #
# and has been linked to a the VNET or a centralized DNS solution #
###################################################################
resource "azurerm_private_endpoint" "peblob" {
  name                = "pe-blob-${azurerm_storage_account.sa.name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private-endpoints.id

  private_service_connection {
    name                           = "pe-connection-blob-${azurerm_storage_account.sa.name}"
    private_connection_resource_id = azurerm_storage_account.sa.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
  
  private_dns_zone_group {
    name                 = "privatelink.blob.core.windows.net"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_zone.id]
  }

  lifecycle {
    ignore_changes = all
  }

}

