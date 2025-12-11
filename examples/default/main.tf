# Copyright IBM Corp. 2025
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "nomad" {
  source = "../.."

  # --- Common --- #
  friendly_name_prefix = var.friendly_name_prefix
  common_tags          = var.common_tags
  location             = var.location
  resource_group_name  = var.resource_group_name

  # --- Bootstrap --- #
  nomad_key_vault_name                  = var.nomad_key_vault_name
  nomad_license_secret_id               = var.nomad_license_secret_id
  nomad_gossip_encryption_key_secret_id = var.nomad_gossip_encryption_key_secret_id
  nomad_tls_cert_secret_id              = var.nomad_tls_cert_secret_id
  nomad_tls_privkey_secret_id           = var.nomad_tls_privkey_secret_id
  nomad_tls_ca_bundle_secret_id         = var.nomad_tls_ca_bundle_secret_id

  # --- Compute --- #
  vm_size           = var.vm_size
  nomad_nodes       = var.nomad_nodes
  vm_ssh_public_key = var.vm_ssh_public_key

  # --- Networking --- #
  vnet_id                  = var.vnet_id
  associate_public_ip      = var.associate_public_ip
  autopilot_health_enabled = var.autopilot_health_enabled
  lb_is_internal           = var.lb_is_internal
  create_load_balancer     = var.create_load_balancer
  subnet_id                = var.subnet_id
  vnet_name                = var.vnet_name
  lb_subnet_name           = var.lb_subnet_name

  # DNS (optional)
  create_nomad_public_dns_record = var.create_nomad_public_dns_record
  public_dns_zone_name           = var.public_dns_zone_name
  public_dns_zone_rg             = var.public_dns_zone_rg
  nomad_fqdn                     = var.nomad_fqdn

  # --- Nomad config settings --- #
  nomad_version          = var.nomad_version
  nomad_tls_enabled      = var.nomad_tls_enabled
  nomad_client           = var.nomad_client
  nomad_server           = var.nomad_server
  nomad_datacenter       = var.nomad_datacenter
  nomad_location         = var.location
  nomad_ui_enabled       = var.nomad_ui_enabled
  nomad_upstream_servers = var.nomad_upstream_servers
  nomad_acl_enabled      = var.nomad_acl_enabled

}
