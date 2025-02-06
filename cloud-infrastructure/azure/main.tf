
resource "azurerm_resource_group" "azure_resource_group" {
  # Mandatory parameters
  name     = var.resource_group_name
  location = var.resource_group_location
  # Optional parameters
  tags     = var.resource_group_tags
}

resource "azurerm_virtual_network" "azure_virtual_network" {
  # Mandatory parameters
  name                = var.virtual_network_name
  address_space       = var.virtual_network_cidr
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  # Optional parameters
  tags                 = var.virtual_network_tags
}

resource "azurerm_subnet" "azure_subnet" {
  # Mandatory parameters
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group._azure_resource_group.name
  virtual_network_name = azurerm_virtual_network._azure_virtual_network.name
  address_prefixes     = var.subnet_address_prefixes
  }

resource "azurerm_virtual_machine" "azure_virtual_machine" {
  # Mandatory parameters
  name                  = var.vm_name
  location              = var.resource_group_location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = var.vm_size

  storage_os_disk {
    name              = var.vm_storage_os_disk_name
    caching           = var.vm_storage_os_disk_caching
    create_option     = var.vm_storage_os_disk_create_option
    managed_disk_type = var.vm_storage_os_disk_managed_disk_type
  }
  
  # Optional parameters
  storage_image_reference {
    publisher = var.vm_image.publisher
    offer     = var.vm_image.offer
    sku       = var.vm_image.sku
    version   = var.vm_image.version
  }
  os_profile {
    computer_name  = var.vm_name
    admin_username = var.vm_admin_username
    custom_data    = filebase64(var.vm_custom_data)
  }
  
  os_profile_linux_config {
    disable_password_authentication = var.vm_disable_password_authentication
    ssh_keys {
        path     = "/home/{username}/.ssh/authorized_keys" # hardcoded becuase it is the only possible value
        key_data = var.sshkey_public_key
    }
  }

  tags     = var.vm_tags
}


resource "azurerm_network_interface" "_azure_network_interface" {
  # Mandatory parameters
  for_each = { for x, network_interface in var.network_interfaces : x => network_interface }

  name                = each.value.network_interface_name
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  
  dynamic "ip_configuration" {
    for_each = coalesce([try(var.network_interface_ip_configuration[each.key], var.network_interface_ip_configuration[0])], [])
    content {
      name                          = try(ip_configurations.value.name, null)
      subnet_id                     = try(var.network_interface_subnet_id, null)
      private_ip_address_allocation = try(ip_configurations.value.private_ip_address_allocation, null)
      public_ip_address_id          = try(var.network_interface_ip_public_id, null)
    }
  }

  # Optional parameters
  tags = each.value.network_interface_tag
}

resource "azurerm_virtual_network_gateway" "example" {
  name                = "test"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  type     = "Vpn"
  sku           = "Basic"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.example.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.example.id
  }

}

resource "azurerm_express_route_circuit" "example" {
  name                  = "expressRoute1"
  resource_group_name   = azurerm_resource_group.example.name
  location              = azurerm_resource_group.example.location
  service_provider_name = "Equinix"
  peering_location      = "Silicon Valley"
  bandwidth_in_mbps     = 50

  sku {
    tier   = "Standard"
    family = "MeteredData"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_virtual_network_gateway_connection" "onpremise" {
  name                = "onpremise"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  type                       = "ExpressRoute"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.example.id
  express_route_circuit_id   =
}

resource "azurerm_express_route_circuit" "example" {
  name                  = "expressRoute1"
  resource_group_name   = azurerm_resource_group.example.name
  location              = azurerm_resource_group.example.location
  service_provider_name = "Equinix"
  peering_location      = "Silicon Valley"
  bandwidth_in_mbps     = 50

  sku {
    tier   = "Standard"
    family = "MeteredData"
  }
  tags = {
    environment = "Production"
  }
}

resource "azurerm_express_route_circuit_peering" "example" {
  peering_type                  = "MicrosoftPeering"
  express_route_circuit_name    = azurerm_express_route_circuit.example.name
  resource_group_name           = azurerm_resource_group.example.name
  peer_asn                      = 100
  primary_peer_address_prefix   = "123.0.0.0/30"
  secondary_peer_address_prefix = "123.0.0.4/30"
  ipv4_enabled                  = true
  vlan_id                       = 300
}