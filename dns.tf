# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# DNS zone lookup
#------------------------------------------------------------------------------
data "azurerm_dns_zone" "nomad" {
  count = var.create_nomad_public_dns_record == true && var.public_dns_zone_name != null ? 1 : 0

  name                = var.public_dns_zone_name
  resource_group_name = var.public_dns_zone_rg
}

data "azurerm_private_dns_zone" "nomad" {
  count = var.create_nomad_private_dns_record == true && var.private_dns_zone_name != null ? 1 : 0

  name                = var.private_dns_zone_name
  resource_group_name = var.private_dns_zone_rg
}

#------------------------------------------------------------------------------
# DNS A record
#------------------------------------------------------------------------------
locals {
  nomad_hostname_public  = var.create_nomad_public_dns_record == true && var.public_dns_zone_name != null ? trimsuffix(substr(var.nomad_fqdn, 0, length(var.nomad_fqdn) - length(var.public_dns_zone_name) - 1), ".") : var.nomad_fqdn
  nomad_hostname_private = var.create_nomad_private_dns_record == true && var.private_dns_zone_name != null ? trim(split(var.private_dns_zone_name, var.nomad_fqdn)[0], ".") : var.nomad_fqdn
}

resource "azurerm_dns_a_record" "nomad" {
  count = var.create_load_balancer && var.create_nomad_public_dns_record == true && var.public_dns_zone_name != null ? 1 : 0

  name                = local.nomad_hostname_public
  resource_group_name = var.public_dns_zone_rg
  zone_name           = data.azurerm_dns_zone.nomad[0].name
  ttl                 = 300
  records             = var.lb_is_internal == true ? [azurerm_lb.nomad[0].private_ip_address] : null
  target_resource_id  = var.lb_is_internal == false ? azurerm_public_ip.nomad_frontend_ip[0].id : null
  tags                = var.common_tags
}

resource "azurerm_private_dns_a_record" "nomad" {
  count = var.create_load_balancer && var.create_nomad_private_dns_record == true && var.private_dns_zone_name != null ? 1 : 0

  name                = local.nomad_hostname_private
  resource_group_name = var.private_dns_zone_rg
  zone_name           = data.azurerm_private_dns_zone.nomad[0].name
  ttl                 = 300
  records             = var.lb_is_internal == true ? [azurerm_lb.nomad[0].private_ip_address] : null
  tags                = var.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "nomad" {
  count = var.create_load_balancer && var.create_nomad_private_dns_record == true && var.private_dns_zone_name != null ? 1 : 0

  name                  = "${var.friendly_name_prefix}-nomad-priv-dns-zone-vnet-link"
  resource_group_name   = var.private_dns_zone_rg
  private_dns_zone_name = data.azurerm_private_dns_zone.nomad[0].name
  virtual_network_id    = var.vnet_id
  tags                  = var.common_tags
}
