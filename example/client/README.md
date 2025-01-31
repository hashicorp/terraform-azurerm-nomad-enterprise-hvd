# Nomad Enterprise HVD - Default Example

This example will deploy Nomad Clients to join an existing Nomad Cluster. The clients can join via specified DNS/IP addresses using the `nomad_upstream_servers` variable or other configurations like custom TLS settings for secure communication. No runtimes will be enabled by default. To enable a runtime, modify the `install_runtime` function in the `templates/nomad_custom_data.sh.tpl` file to include the desired configurations.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_nomad"></a> [nomad](#module\_nomad) | ../.. | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_friendly_name_prefix"></a> [friendly\_name\_prefix](#input\_friendly\_name\_prefix) | Friendly name prefix used for uniquely naming Azure resources. | `string` | n/a | yes |
| <a name="input_instance_subnets"></a> [instance\_subnets](#input\_instance\_subnets) | List of Azure subnet resource IDs for instance(s) to be deployed into. | `list(string)` | n/a | yes |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | SSH key name, already registered in Azure, to use for instance access. | `string` | n/a | yes |
| <a name="input_lb_subnet_ids"></a> [lb\_subnet\_ids](#input\_lb\_subnet\_ids) | List of subnet IDs to use for the load balancer. If `lb_is_internal` is `false`, then these should be public subnets. Otherwise, these should be private subnets. | `list(string)` | n/a | yes |
| <a name="input_nomad_client"></a> [nomad\_client](#input\_nomad\_client) | Boolean to enable the Nomad client agent. | `bool` | n/a | yes |
| <a name="input_nomad_datacenter"></a> [nomad\_datacenter](#input\_nomad\_datacenter) | Specifies the data center of the local agent. A datacenter is an abstract grouping of clients within a region. Clients are not required to be in the same datacenter as the servers they are joined with, but do need to be in the same region. | `string` | n/a | yes |
| <a name="input_nomad_server"></a> [nomad\_server](#input\_nomad\_server) | Boolean to enable the Nomad server agent. | `bool` | n/a | yes |
| <a name="input_nomad_tls_ca_bundle_secret_id"></a> [nomad\_tls\_ca\_bundle\_secret\_id](#input\_nomad\_tls\_ca\_bundle\_secret\_id) | URI of Key Vault secret for private/custom TLS Certificate Authority (CA) bundle in PEM format. Secret must be stored as a base64-encoded string. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure region where Nomad will be deployed. | `string` | n/a | yes |
| <a name="input_vnet_id"></a> [vnet\_id](#input\_vnet\_id) | ID of the Azure Virtual Network where resources are deployed. | `string` | n/a | yes |
| <a name="input_additional_package_names"></a> [additional\_package\_names](#input\_additional\_package\_names) | List of additional repository package names to install. | `list(string)` | `[]` | no |
| <a name="input_additional_network_security_group_ids"></a> [additional\_network\_security\_group\_ids](#input\_additional\_network\_security\_group\_ids) | List of Azure Network Security Group IDs to apply to all cluster nodes. | `list(string)` | `[]` | no |
| <a name="input_health_probe_grace_period"></a> [health\_probe\_grace\_period](#input\_health\_probe\_grace\_period) | The amount of time to wait for a new Nomad VM instance to become healthy. | `number` | `600` | no |
| <a name="input_associate_public_ip"></a> [associate\_public\_ip](#input\_associate\_public\_ip) | Whether public IPv4 addresses should automatically be attached to cluster nodes. | `bool` | `false` | no |
| <a name="input_autopilot_health_enabled"></a> [autopilot\_health\_enabled](#input\_autopilot\_health\_enabled) | Whether autopilot upgrade migration validation is performed for server nodes at boot-time. | `bool` | `true` | no |
| <a name="input_allowed_ingress_cidr"></a> [allowed\_ingress\_cidr](#input\_allowed\_ingress\_cidr) | List of CIDR ranges to allow ingress traffic on port 443 or 80 to Nomad server or load balancer. | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_cni_version"></a> [cni\_version](#input\_cni\_version) | Version of CNI plugin to install. | `string` | `"1.6.0"` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Map of common tags for taggable Azure resources. | `map(string)` | `{}` | no |
| <a name="input_create_load_balancer"></a> [create\_load\_balancer](#input\_create\_load\_balancer) | Boolean to create a Load Balancer for Nomad. | `bool` | `true` | no |
| <a name="input_create_dns_zone"></a> [create\_dns\_zone](#input\_create\_dns\_zone) | Boolean to create a DNS Zone for Nomad. | `bool` | `false` | no |
| <a name="input_os_disk_size_gb"></a> [os\_disk\_size\_gb](#input\_os\_disk\_size\_gb) | Size (GB) of the OS disk for Nomad VMs. | `number` | `50` | no |
| <a name="input_data_disk_size_gb"></a> [data\_disk\_size\_gb](#input\_data\_disk\_size\_gb) | Size (GB) of the data disk for Nomad VMs. | `number` | `50` | no |
| <a name="input_enable_disk_encryption"></a> [enable\_disk\_encryption](#input\_enable\_disk\_encryption) | Boolean to enable encryption for disks on the Nomad VMs. | `bool` | `true` | no |
| <a name="input_nomad_version"></a> [nomad\_version](#input\_nomad\_version) | Version of Nomad to install. | `string` | `"1.9.0+ent"` | no |
| <a name="input_permit_all_outbound"></a> [permit\_all\_outbound](#input\_permit\_all\_outbound) | Whether broad (0.0.0.0/0) outbound traffic should be permitted on cluster nodes. | `bool` | `true` | no |
<!-- END_TF_DOCS -->
