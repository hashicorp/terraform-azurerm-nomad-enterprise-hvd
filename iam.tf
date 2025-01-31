# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Azure Role Assignment and Key Vault Access Policies
#------------------------------------------------------------------------------

# Principal ID for the VM identity (used as a placeholder, replace with your identity information)
resource "azurerm_user_assigned_identity" "nomad_vm_identity" {
  name                = "${var.friendly_name_prefix}-vm-identity"
  location            = var.location
  resource_group_name = var.resource_group_name
}

data "azurerm_subscription" "primary" {}

data "azurerm_client_config" "current" {}

# Custom Role Definition for Nomad VM Access
resource "azurerm_role_assignment" "nomad_vm_reader_role" {
  principal_id            = azurerm_user_assigned_identity.nomad_vm_identity.principal_id
  role_definition_name    = "Reader" # Allows read access to all resources in the resource group
  scope                   = data.azurerm_resource_group.nomad_rg.id
}

#------------------------------------------------------------------------------
# Key Vault Configuration
#------------------------------------------------------------------------------
resource "azurerm_key_vault" "nomad_keyvault" {
  name                     = "${var.friendly_name_prefix}-keyvault"
  location                 = var.location
  resource_group_name      = var.resource_group_name
  sku_name                 = "standard"
  tenant_id                = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled = false
  tags                     = var.common_tags
}