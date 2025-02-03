resource "azurerm_virtual_network" "this" {
  for_each            = { for key, value in var.vnets : key => value if value.existing == false }
  name                = each.value.name
  address_space       = each.value.address_space
  resource_group_name = var.resource_group
  location            = var.location
}

resource "azurerm_subnet" "this" {
  for_each             = { for subnet in local.flattened_subnets : "${subnet.vnet_key}-${subnet.subnet_key}" => subnet }
  name                 = each.value.subnet.name
  resource_group_name  = var.resource_group
  virtual_network_name = each.value.vnet.existing ? each.value.vnet_key : azurerm_virtual_network.this[each.value.vnet_key].name
  address_prefixes     = each.value.subnet.address_prefixes
  service_endpoints    = each.value.subnet.service_endpoints

  dynamic "delegation" {
    for_each = each.value.subnet.delegations != null ? each.value.subnet.delegations : {}
    content {
      name = delegation.key
      service_delegation {
        name    = delegation.value.service_name
        actions = delegation.value.actions
      }
    }
  }
}