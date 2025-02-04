# Copyright (c) HashiCorp, Inc.
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
  nomad_license_secret_id               = var.nomad_license_secret_id
  nomad_gossip_encryption_key_secret_id = var.nomad_gossip_encryption_key_secret_id
  nomad_tls_cert_secret_id              = var.nomad_tls_cert_secret_id
  nomad_tls_privkey_secret_id           = var.nomad_tls_privkey_secret_id
  nomad_tls_ca_bundle_secret_id         = var.nomad_tls_ca_bundle_secret_id

  # --- Compute --- #
  vm_size      = var.vm_size
  ssh_key_name = var.ssh_key_name
  nomad_nodes  = var.nomad_nodes

  # --- Networking --- #
  permit_all_egress        = var.permit_all_egress
  vnet_id                  = var.vnet_id
  vnet_name                = var.vnet_name
  associate_public_ip      = var.associate_public_ip
  autopilot_health_enabled = var.autopilot_health_enabled
  lb_is_internal           = var.lb_is_internal
  cidr_allow_ingress_nomad = var.cidr_allow_ingress_nomad
  create_load_balancer     = var.create_load_balancer
  #subnet_id                = var.subnet_id
  subnet_name = var.subnet_name

  # --- Nomad config settings --- #
  nomad_version          = var.nomad_version
  nomad_tls_enabled      = var.nomad_tls_enabled
  nomad_client           = var.nomad_client
  nomad_server           = var.nomad_server
  nomad_datacenter       = var.nomad_datacenter
  nomad_location         = var.nomad_location
  nomad_ui_enabled       = var.nomad_ui_enabled
  nomad_upstream_servers = var.nomad_upstream_servers
  nomad_acl_enabled      = var.nomad_acl_enabled

  # --- DNS --- #
  create_dns_nomad_record = var.create_dns_nomad_record
  nomad_dns_zone_name     = var.dns_zone_name
  nomad_fqdn              = var.nomad_fqdn
}
