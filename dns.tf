# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


#------------------------------------------------------------------------------
# Azure DNS Zone and record for Nomad
#------------------------------------------------------------------------------

# Azure DNS Zone
resource "azurerm_dns_zone" "nomad" {
  count               = var.create_dns_nomad_record && var.nomad_dns_zone_name != null && var.nomad_fqdn != null ? 1 : 0
  name                = var.nomad_dns_zone_name
  resource_group_name = var.resource_group_name
  tags                = merge({ "Name" = "${var.friendly_name_prefix}-nomad-dns" }, var.common_tags)
}

# DNS A Record for Nomad Load Balancer
resource "azurerm_dns_a_record" "nomad_alias_record" {
  count               = var.create_dns_nomad_record && var.nomad_dns_zone_name != null && var.nomad_fqdn != null && var.create_load_balancer ? 1 : 0
  name                = var.nomad_fqdn
  zone_name           = azurerm_dns_zone.nomad[0].name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_lb.nomad_lb.frontend_ip_configuration[0].private_ip_address]

  tags = merge({ "Name" = "${var.friendly_name_prefix}-nomad-alias-record" }, var.common_tags)
}
