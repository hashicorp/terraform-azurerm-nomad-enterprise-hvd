# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

data "azurerm_resource_group" "nomad_rg" {
  name = var.resource_group_name
}
data "azurerm_subscription" "primary" {}

data "azurerm_client_config" "current" {}
