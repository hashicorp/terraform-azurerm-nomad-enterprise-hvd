# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# User Data (cloud-init) Arguments for Nomad on Azure
#------------------------------------------------------------------------------


locals {
  custom_data_args = {
    custom_startup_script_template = var.custom_startup_script_template != null ? "${path.cwd}/templates/${var.custom_startup_script_template}" : "${path.module}/templates/nomad_custom_data.sh.tpl"

    # Prereqs
    nomad_license_secret_id               = var.nomad_license_secret_id
    nomad_gossip_encryption_key_secret_id = var.nomad_gossip_encryption_key_secret_id
    nomad_tls_cert_secret_id              = var.nomad_tls_cert_secret_id == null ? "NONE" : var.nomad_tls_cert_secret_id
    nomad_tls_privkey_secret_id           = var.nomad_tls_privkey_secret_id == null ? "NONE" : var.nomad_tls_privkey_secret_id
    nomad_tls_ca_bundle_secret_id         = var.nomad_tls_ca_bundle_secret_id == null ? "NONE" : var.nomad_tls_ca_bundle_secret_id
    additional_package_names              = join(" ", var.additional_package_names)

    # Nomad Settings
    nomad_version            = var.nomad_version
    name                     = "${var.friendly_name_prefix}-nomad"
    systemd_dir              = "/etc/systemd/system"
    nomad_dir_bin            = "/usr/bin"
    cni_dir_bin              = "/opt/cni/bin"
    nomad_dir_config         = "/etc/nomad.d"
    nomad_dir_home           = "/opt/nomad"
    nomad_install_url        = format("https://releases.hashicorp.com/nomad/%s/nomad_%s_linux_%s.zip", var.nomad_version, var.nomad_version, var.nomad_architecture)
    cni_install_url          = format("https://github.com/containernetworking/plugins/releases/download/v%s/cni-plugins-linux-%s-v%s.tgz", var.cni_version, var.nomad_architecture, var.cni_version)
    azure_location           = var.location
    nomad_tls_enabled        = var.nomad_tls_enabled
    nomad_acl_enabled        = var.nomad_acl_enabled
    nomad_client             = var.nomad_client
    nomad_server             = var.nomad_server
    nomad_datacenter         = var.nomad_datacenter
    nomad_location           = var.nomad_location == null ? var.location : var.nomad_location
    nomad_ui_enabled         = var.nomad_ui_enabled
    nomad_upstream_servers   = var.nomad_upstream_servers
    nomad_upstream_tag_key   = var.nomad_upstream_tag_key
    nomad_upstream_tag_value = var.nomad_upstream_tag_value
    nomad_nodes              = var.nomad_nodes
    autopilot_health_enabled = var.autopilot_health_enabled
  }
}

# #------------------------------------------------------------------------------
# # Custom VM image lookup
# #------------------------------------------------------------------------------
# data "azurerm_image" "custom" {
#   count = var.vm_custom_image_name == null ? 0 : 1

#   name                = var.vm_custom_image_name
#   resource_group_name = var.vm_custom_image_rg_name
# }

#------------------------------------------------------------------------------
# VM Configuration
#------------------------------------------------------------------------------
resource "azurerm_linux_virtual_machine_scale_set" "nomad" {
  name                = "${var.friendly_name_prefix}-nomad-vmss"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.vm_size
  instances           = var.nomad_nodes
  admin_username      = var.admin_username

  dynamic "admin_ssh_key" {
    for_each = var.vm_ssh_public_key != null ? [1] : []

    content {
      username   = var.admin_username
      public_key = var.vm_ssh_public_key
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.nomad_vm_identity.id]
  }

  custom_data = base64encode(templatefile("${local.custom_startup_script_template}", local.custom_data_args))

  source_image_id = var.vm_custom_image_name != null ? data.azurerm_image.custom[0].id : null
  dynamic "source_image_reference" {
    for_each = var.vm_custom_image_name == null ? [true] : []

    content {
      publisher = local.vm_image_publisher
      offer     = local.vm_image_offer
      sku       = local.vm_image_sku
      version   = data.azurerm_platform_image.latest_os_image.version
    }
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 50
  }

  data_disk {
    lun                  = 0
    caching              = "ReadWrite"
    create_option        = "Empty"
    disk_size_gb         = 10
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name                          = "${var.friendly_name_prefix}-nomad-nic"
    primary                       = true
    network_security_group_id     = azurerm_network_security_group.nomad.id
    enable_accelerated_networking = true

    ip_configuration {
      name                                   = "${var.friendly_name_prefix}-nomad-ip"
      primary                                = true
      subnet_id                              = var.subnet_id
      load_balancer_backend_address_pool_ids = var.create_load_balancer ? [azurerm_lb_backend_address_pool.nomad_backend_pool[0].id] : []
    }
  }

  dynamic "boot_diagnostics" {
    for_each = var.vm_enable_boot_diagnostics == true ? [1] : []
    content {}
  }

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-boundary-vmss" },
    var.common_tags
  )

}

#------------------------------------------------------------------------------
# Network Interface and Security Groups
#------------------------------------------------------------------------------
resource "azurerm_network_security_group" "nomad" {
  name                = "${var.friendly_name_prefix}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "allow_ssh"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "0.0.0.0/0"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_nomad_4646"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "4646"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_gossip"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "4647-4648"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_udp_gossip"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "4648"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-nsg" },
    var.common_tags
  )
}
