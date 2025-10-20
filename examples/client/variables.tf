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

variable "availability_zones" {
  type        = set(string)
  description = "List of Azure Availability Zones to spread nomad resources across."
  default     = ["1", "2", "3"]

  validation {
    condition     = alltrue([for az in var.availability_zones : contains(["1", "2", "3"], az)])
    error_message = "Availability zone must be one of, or a combination of '1', '2', '3'."
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
variable "nomad_key_vault_name" {
  type        = string
  description = "ID of Azure Key Vault secret for Nomad license file."
  default     = null
}
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

variable "vnet_name" {
  type        = string
  description = "Name of the Azure VNet where resources are deployed."
}

variable "lb_subnet_name" {
  type        = string
  description = "Name of the Azure lb subnet where the lb resources should be deployed too."
  default     = null
  validation {
    condition     = var.create_load_balancer ? var.lb_subnet_name != null : true
    error_message = "lb_subnet_name must be provided when create_load_balancer is true."
  }
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

variable "lb_private_ip" {
  type        = string
  description = "Private IP address for internal Azure Load Balancer. Only valid when `lb_is_internal` is `true`."
  default     = null
  validation {
    condition     = var.lb_is_internal ? var.lb_private_ip != null : true
    error_message = "Private IP address must be provided when `lb_is_internal` is `true`."
  }
}

variable "frontend_ip_config_name" {
  type        = string
  description = "The name of the frontend IP configuration to which the rule is associated."
  default     = "PublicIPAddress"
}

#------------------------------------------------------------------------------
# DNS
#------------------------------------------------------------------------------
variable "create_nomad_public_dns_record" {
  type        = bool
  description = "Boolean to create a DNS record for nomad in a public Azure DNS zone. `public_dns_zone_name` must also be provided when `true`."
  default     = false
}

variable "create_nomad_private_dns_record" {
  type        = bool
  description = "Boolean to create a DNS record for nomad in a private Azure DNS zone. `private_dns_zone_name` must also be provided when `true`."
  default     = false
}

variable "public_dns_zone_name" {
  type        = string
  description = "Name of existing public Azure DNS zone to create DNS record in. Required when `create_nomad_public_dns_record` is `true`."
  default     = null
}

variable "public_dns_zone_rg" {
  type        = string
  description = "Name of Resource Group where `public_dns_zone_name` resides. Required when `create_nomad_public_dns_record` is `true`."
  default     = null
}

variable "private_dns_zone_name" {
  type        = string
  description = "Name of existing private Azure DNS zone to create DNS record in. Required when `create_nomad_private_dns_record` is `true`."
  default     = null
}

variable "private_dns_zone_rg" {
  type        = string
  description = "Name of Resource Group where `private_dns_zone_name` resides. Required when `create_nomad_private_dns_record` is `true`."
  default     = null
}

#------------------------------------------------------------------------------
# Compute
#------------------------------------------------------------------------------
variable "vm_os_image" {
  description = "The OS image to use for the VM. Options are: redhat8, redhat9, ubuntu2204, ubuntu2404."
  type        = string
  default     = "ubuntu2404"

  validation {
    condition     = contains(["redhat8", "redhat9", "ubuntu2204", "ubuntu2404"], var.vm_os_image)
    error_message = "Value must be one of 'redhat8', 'redhat9', 'ubuntu2204', or 'ubuntu2404'."
  }
}

variable "vm_custom_image_name" {
  type        = string
  description = "Name of custom VM image to use for VMSS. If not using a custom image, leave this blank."
  default     = null
}

variable "vm_custom_image_rg_name" {
  type        = string
  description = "Name of Resource Group where `vm_custom_image_name` image resides. Only valid if `vm_custom_image_name` is not `null`."
  default     = null

  validation {
    condition     = var.vm_custom_image_name != null ? var.vm_custom_image_rg_name != null : true
    error_message = "A value is required when `vm_custom_image_name` is not `null`."
  }
}

variable "vm_size" {
  type        = string
  description = "Azure VM size for Nomad VMs."
  default     = "Standard_D2s_v3"
}

variable "vm_image_version" {
  type        = string
  description = "Version of the VM image."
  default     = "latest"
}

variable "nomad_nodes" {
  type        = number
  description = "Number of Nomad nodes to deploy."
  default     = 2
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

variable "vm_ssh_public_key" {
  type        = string
  description = "SSH public key for VMs in VMSS."
  default     = null
}

variable "admin_username" {
  type        = string
  description = "Admin username for VM instance."
  default     = "ubuntu"
}

variable "vm_enable_boot_diagnostics" {
  type        = bool
  description = "Boolean to enable boot diagnostics for VMSS."
  default     = true
}

variable "custom_startup_script_template" {
  type        = string
  description = "Name of custom startup script template file. File must exist within a directory named `./templates` within your current working directory."
  default     = null

  validation {
    condition     = var.custom_startup_script_template != null ? fileexists("${path.cwd}/templates/${var.custom_startup_script_template}") : true
    error_message = "File not found. Ensure the file exists within a directory named `./templates` within your current working directory."
  }
}
