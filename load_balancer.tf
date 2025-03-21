# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


#------------------------------------------------------------------------------
# Azure Load Balancer 
#------------------------------------------------------------------------------
data "azurerm_subnet" "lb_subnet" {
  count = var.create_load_balancer ? 1 : 0

  name                 = var.lb_subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resource_group_name
}

resource "azurerm_public_ip" "nomad_frontend_ip" {
  count = var.lb_is_internal == false ? 1 : 0

  name                = "${var.friendly_name_prefix}-nomad-frontend-ip"
  location            = data.azurerm_resource_group.nomad_rg.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Load Balancer Configuration
resource "azurerm_lb" "nomad" {
  count = var.create_load_balancer ? 1 : 0

  name                = "${var.friendly_name_prefix}-nomad-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  frontend_ip_configuration {
    name                          = var.frontend_ip_config_name
    zones                         = var.lb_is_internal == true ? var.availability_zones : null
    public_ip_address_id          = var.lb_is_internal == false ? azurerm_public_ip.nomad_frontend_ip[0].id : null
    subnet_id                     = var.lb_is_internal == true ? data.azurerm_subnet.lb_subnet[0].id : null
    private_ip_address_allocation = var.lb_is_internal == true ? "Static" : null
    private_ip_address            = var.lb_is_internal == true ? var.lb_private_ip : null
  }

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-nomad-lb" },
    var.common_tags
  )
}

# Backend Pool
resource "azurerm_lb_backend_address_pool" "nomad_backend_pool" {
  count = var.create_load_balancer ? 1 : 0

  loadbalancer_id = azurerm_lb.nomad[0].id
  name            = "${var.friendly_name_prefix}-nomad-backend-pool"
}

# Load Balancer Health Probe
resource "azurerm_lb_probe" "nomad_probe" {
  count = var.create_load_balancer ? 1 : 0

  loadbalancer_id     = azurerm_lb.nomad[0].id
  name                = "${var.friendly_name_prefix}-nomad-probe"
  protocol            = var.nomad_tls_enabled ? "Https" : "Http"
  port                = 4646
  request_path        = "/v1/agent/health"
  interval_in_seconds = 30
  number_of_probes    = 5
}

# Load Balancer Rule for Nomad (Port 4646)
resource "azurerm_lb_rule" "nomad_rule_4646" {
  count = var.create_load_balancer ? 1 : 0

  loadbalancer_id                = azurerm_lb.nomad[0].id
  name                           = "${var.friendly_name_prefix}-nomad-lb-rule-4646"
  protocol                       = "Tcp"
  frontend_port                  = var.nomad_tls_enabled ? 443 : 80
  backend_port                   = 4646
  frontend_ip_configuration_name = azurerm_lb.nomad[0].frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.nomad_backend_pool[0].id]
  probe_id                       = azurerm_lb_probe.nomad_probe[0].id

  idle_timeout_in_minutes = 15
}

#------------------------------------------------------------------------------
# Network Security Groups (NSG) for Load Balancer
#------------------------------------------------------------------------------
# Ingress Security Group for Load Balancer
resource "azurerm_network_security_group" "lb_nsg" {
  count = var.create_load_balancer ? 1 : 0

  name                = "${var.friendly_name_prefix}-nomad-lb-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowNomadInboundFromCIDR"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = var.nomad_tls_enabled ? "443" : "80"
    source_address_prefixes    = var.cidr_allow_ingress_nomad
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowNomadInboundFromVMs"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = var.nomad_tls_enabled ? "443" : "80"
    source_address_prefix      = data.azurerm_subnet.lb_subnet[0].address_prefix
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "0.0.0.0/0"
  }

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-nomad-lb-nsg" },
    var.common_tags
  )
}

resource "azurerm_network_interface" "nomad_nic" {
  count = var.create_load_balancer ? 1 : 0

  name                = "nomad-lb-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = data.azurerm_subnet.lb_subnet[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

# Associate the Security Groups with Load Balancer Network Interfaces
resource "azurerm_network_interface_security_group_association" "lb_nsg_association" {
  count = var.create_load_balancer ? 1 : 0

  network_interface_id      = azurerm_network_interface.nomad_nic[0].id
  network_security_group_id = azurerm_network_security_group.lb_nsg[0].id
}
