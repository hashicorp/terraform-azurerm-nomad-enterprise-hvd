# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Azure Role Assignment and Key Vault Access Policies
#------------------------------------------------------------------------------

data "azurerm_subscription" "primary" {}

data "azurerm_client_config" "current" {}

data "azurerm_key_vault" "nomad_keyvault" {
  name                = var.nomad_key_vault_name 
  resource_group_name = var.resource_group_name
}

# Principal ID for the VM identity (used as a placeholder, replace with your identity information)
resource "azurerm_user_assigned_identity" "nomad_vm_identity" {
  name                = "${var.friendly_name_prefix}-vm-identity"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Custom Role Definition for Nomad VM Access
resource "azurerm_role_assignment" "nomad_vm_reader_role" {
  principal_id            = azurerm_user_assigned_identity.nomad_vm_identity.principal_id
  role_definition_name    = "Reader" # Allows read access to all resources in the resource group
  scope                   = data.azurerm_resource_group.nomad_rg.id
}

resource "azurerm_key_vault_access_policy" "nomad_vmss_keyvault_access" {
  key_vault_id = data.azurerm_key_vault.nomad_keyvault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.nomad_vm_identity.principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}
