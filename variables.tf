# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Common
#------------------------------------------------------------------------------
variable "friendly_name_prefix" {
  type        = string
  description = "Friendly name prefix used for uniquely naming Azure resources."
  validation {
    condition     = length(var.friendly_name_prefix) > 0 && length(var.friendly_name_prefix) < 17
    error_message = "Friendly name prefix must be between 1 and 16 characters."
  }
}

variable "create_resource_group" {
  type        = bool
  description = "Boolean to create a new Azure resource group for this deployment. Set to `false` if you want to use an existing resource group."
  default     = false
}

variable "resource_group_name" {
  type        = string
  description = "Name of Azure resource group to create or name of existing resource group to use (if `create_resource_group` is `false`)."
}

variable "location" {
  type        = string
  description = "Azure region to use for this deployment."

  # az account list-locations --output json | jq -r '.[].name' | sort | tr '\n' ' ' | sed 's/ /", "/g' | sed 's/^/"/' | sed 's/, "$//'
  validation {
    condition     = contains(["asia", "asiapacific", "australia", "australiacentral", "australiacentral2", "australiaeast", "australiasoutheast", "brazil", "brazilsouth", "brazilsoutheast", "brazilus", "canada", "canadacentral", "canadaeast", "centralindia", "centralus", "centraluseuap", "centralusstage", "eastasia", "eastasiastage", "eastus", "eastus2", "eastus2euap", "eastus2stage", "eastusstage", "eastusstg", "europe", "france", "francecentral", "francesouth", "germany", "germanynorth", "germanywestcentral", "global", "india", "israel", "israelcentral", "italy", "italynorth", "japan", "japaneast", "japanwest", "jioindiacentral", "jioindiawest", "korea", "koreacentral", "koreasouth", "mexicocentral", "newzealand", "northcentralus", "northcentralusstage", "northeurope", "norway", "norwayeast", "norwaywest", "poland", "polandcentral", "qatar", "qatarcentral", "singapore", "southafrica", "southafricanorth", "southafricawest", "southcentralus", "southcentralusstage", "southcentralusstg", "southeastasia", "southeastasiastage", "southindia", "spaincentral", "sweden", "swedencentral", "switzerland", "switzerlandnorth", "switzerlandwest", "uae", "uaecentral", "uaenorth", "uk", "uksouth", "ukwest", "unitedstates", "unitedstateseuap", "westcentralus", "westeurope", "westindia", "westus", "westus2", "westus2stage", "westus3", "westusstage"], var.location)
    error_message = "Value specified is not a valid Azure region."
  }
}

variable "common_tags" {
  type        = map(string)
  description = "Map of common tags for taggable Azure resources."
  default     = {}
}

#------------------------------------------------------------------------------
# Prerequisites
#------------------------------------------------------------------------------
variable "nomad_license_secret_id" {
  type        = string
  description = "ID of Azure Key Vault secret for Nomad license file."
  default     = null
}

variable "nomad_gossip_encryption_key_secret_id" {
  type        = string
  description = "ID of Azure Key Vault secret for Nomad gossip encryption key."
  default     = null
}

variable "nomad_tls_cert_secret_id" {
  type        = string
  description = "ID of Azure Key Vault secret for Nomad TLS certificate in PEM format. Secret must be stored as a base64-encoded string."
  default     = null
}

variable "nomad_tls_privkey_secret_id" {
  type        = string
  description = "ID of Azure Key Vault secret for Nomad TLS private key in PEM format. Secret must be stored as a base64-encoded string."
  default     = null
}

variable "nomad_tls_ca_bundle_secret_id" {
  type        = string
  description = "ID of Azure Key Vault secret for private/custom TLS Certificate Authority (CA) bundle in PEM format. Secret must be stored as a base64-encoded string."
  default     = null
}

variable "additional_package_names" {
  type        = set(string)
  description = "List of additional repository package names to install on the VMs"
  default     = []
}

#------------------------------------------------------------------------------
# Nomad Configuration Settings
#------------------------------------------------------------------------------
variable "nomad_acl_enabled" {
  type        = bool
  description = "Enable ACLs for Nomad."
  default     = true
}

variable "nomad_client" {
  type        = bool
  description = "Enable the Nomad client agent."
}

variable "nomad_server" {
  type        = bool
  description = "Enable the Nomad server agent."
}

variable "nomad_location" {
  type        = string
  description = "Specifies the region of the local agent. Defaults to the Azure region if null."
  default     = null
}

variable "nomad_datacenter" {
  type        = string
  description = "Specifies the data center of the local agent."
}

variable "nomad_ui_enabled" {
  type        = bool
  description = "Enable the Nomad UI."
  default     = true
}

variable "nomad_upstream_servers" {
  type        = list(string)
  description = "List of Nomad server addresses to join the Nomad client with."
  default     = null
}

variable "nomad_upstream_tag_key" {
  type        = string
  description = "String of the tag key the Nomad client should look for in Azure to join with. Only needed for auto-joining the Nomad client."
  default     = null
}

variable "nomad_upstream_tag_value" {
  type        = string
  description = "String of the tag value the Nomad client should look for in Azure to join with. Only needed for auto-joining the Nomad client."
  default     = null
}

variable "nomad_tls_enabled" {
  type        = bool
  description = "Enable TLS for Nomad."
  default     = true
}

variable "autopilot_health_enabled" {
  type        = bool
  description = "Perform autopilot health checks on Nomad server nodes at boot."
  default     = true
}

variable "nomad_version" {
  type        = string
  description = "Version of Nomad to install."
  default     = "1.9.0+ent"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\+ent$", var.nomad_version))
    error_message = "Value must be in the format 'X.Y.Z+ent'."
  }
}

variable "cni_version" {
  type        = string
  description = "Version of CNI plugin to install."
  default     = "1.6.0"
}

variable "nomad_architecture" {
  type        = string
  description = "Architecture of the Nomad binary to install."
  default     = "amd64"
  validation {
    condition     = can(regex("^(amd64|arm64)$", var.nomad_architecture))
    error_message = "Value must be either 'amd64' or 'arm64'."
  }
}

variable "nomad_fqdn" {
  type        = string
  description = "Fully qualified domain name of the Nomad Cluster. This name should resolve to the load balancer IP address."
  default     = null
}


#------------------------------------------------------------------------------
# Networking
#------------------------------------------------------------------------------
variable "vnet_id" {
  type        = string
  description = "ID of the Azure VNet where resources are deployed."
}

variable "subnet_id" {
  type        = string
  description = "Azure subnet ID for Nomad instance network interface."
}

variable "associate_public_ip" {
  type        = bool
  description = "Whether to associate public IPs with the Nomad cluster VMs."
  default     = false
}

variable "cidr_allow_ingress_nomad" {
  type        = list(string)
  description = "CIDR ranges allowed ingress on port 443/80 for Nomad server/load balancer."
  default     = ["0.0.0.0/0"]
}

variable "permit_all_egress" {
  type        = bool
  description = "Allow unrestricted egress on cluster nodes. Additional rules may be required if disabled."
  default     = true
}

variable "create_load_balancer" {
  type        = bool
  description = "Boolean to create an Azure Load Balancer for Nomad."
  default     = true
}

variable "lb_is_internal" {
  type        = bool
  description = "Create an internal (private) Azure Load Balancer."
  default     = true
}

variable "frontend_ip_config_name" {
  type        = string
  description = "The name of the frontend IP configuration to which the rule is associated."
  default     = "PublicIPAddress"
}

variable "create_dns_nomad_record" {
  type        = bool
  description = "Boolean to create DNS A Record for Nomad in Azure DNS."
  default     = false
}

variable "nomad_dns_zone_name" {
  type        = string
  description = "Azure DNS zone name to create the Nomad A record."
  default     = null
}

#------------------------------------------------------------------------------
# Compute
#------------------------------------------------------------------------------
variable "vm_os_distro" {
  type        = string
  description = "OS distribution type for the Nomad VM. Choose from `Ubuntu`, `RHEL`, or `CentOS`."
  default     = "Ubuntu"

  validation {
    condition     = contains(["Ubuntu", "RHEL", "CentOS"], var.vm_os_distro)
    error_message = "Valid values are `Ubuntu`, `RHEL`, or `CentOS`."
  }
}

variable "vm_sku" {
  type        = string
  description = "SKU for VM size for the VMSS."
  default     = "Standard_D2s_v5"

  validation {
    condition     = can(regex("^[A-Za-z0-9_]+$", var.vm_sku))
    error_message = "Value can only contain alphanumeric characters and underscores."
  }
}

variable "vm_custom_image_name" {
  type        = string
  description = "Name of custom VM image to use for VMSS. If not using a custom image, leave this set to null."
  default     = null
}

variable "vm_custom_image_rg_name" {
  type        = string
  description = "Resource Group name where the custom VM image resides. Only valid if `vm_custom_image_name` is not null."
  default     = null
}

variable "vm_image_publisher" {
  type        = string
  description = "Publisher of the VM image."
  default     = "Canonical"
}

variable "vm_image_offer" {
  type        = string
  description = "Offer of the VM image."
  default     = "0001-com-ubuntu-server-jammy"
}

variable "vm_image_sku" {
  type        = string
  description = "SKU of the VM image."
  default     = "22_04-lts-gen2"
}

variable "vm_size" {
  type        = string
  description = "Azure VM size for Nomad VMs."
  default     = "Standard_D2s_v3"
}

variable "instance_count" {
  type        = number
  description = "Instance count for Azure Scale Set."
  default     = 2
}

variable "vm_image_version" {
  type        = string
  description = "Version of the VM image."
  default     = "latest"
}

variable "nomad_nodes" {
  type        = number
  description = "Number of Nomad nodes to deploy."
  default     = 6
}

variable "disk_size_gb" {
  type        = number
  description = "Size of OS disk for Nomad VMs in GB."
  default     = 50
}

variable "disk_type" {
  type        = string
  description = "Disk type for Nomad VMs. Options: `Standard_LRS`, `Premium_LRS`, etc."
  default     = "Standard_LRS"
}

variable "ssh_key_name" {
  type        = string
  description = "Name of the SSH key for VM access, already registered in Azure."
}

variable "admin_username" {
  type        = string
  description = "Admin username for VM instance."
  default     = "ubuntu"
}

variable "admin_password" {
  type        = string
  description = "Admin password for VM instance."
  default     = "testPassword1234!"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for bastion VM instance."
  default     = null
}
