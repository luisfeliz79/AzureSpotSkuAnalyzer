
# Deploy a virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = local.vnet_name
  address_space       = [local.vnet_address_space]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

# Deploy azure-functions subnet
resource "azurerm_subnet" "azure-functions" {
    name                 = "azure-functions"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = [local.subnet_functions_prefix]
    

    delegation {
        name = "delegation"
        service_delegation {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
    }



}

# Deploy private-endpoints subnet
resource "azurerm_subnet" "private-endpoints" {
    name                 = "private-endpoints"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = [local.subnet_private_endpoints_prefix]
}

# Create a Private DNS Zone
resource "azurerm_private_dns_zone" "blob_zone" {
  name                      = "privatelink.blob.core.windows.net"
  resource_group_name       = azurerm_resource_group.rg.name  
}

# Link the Private DNS Zone to the VNET
resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  name                  = "vnet-link-${azurerm_virtual_network.vnet.name}"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.blob_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}


# Deploy a default Network security group
resource "azurerm_network_security_group" "nsg" {
  name                = "${local.vnet_name}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = local.tags
}

# Associate the NSG to the azure-functions subnet
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.azure-functions.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Associate the NSG to the private-endpoints subnet
resource "azurerm_subnet_network_security_group_association" "nsg_association_pe" {
  subnet_id                 = azurerm_subnet.private-endpoints.id
  network_security_group_id = azurerm_network_security_group.nsg.id
} 
