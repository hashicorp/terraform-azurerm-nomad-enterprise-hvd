# Deployment customizations

This page contains various deployment customizations related to creating your Nomad infrastructure and their corresponding module input variables that you may configure to meet your specific requirements where the default module values do not suffice. All of the module input variables mentioned on this page are optional.


## Custom VM Image

If a custom VM image is preferred over using a standard marketplace image, the following variables may be set:

```hcl
vm_custom_image_name    = "<my-custom-ubuntu-2204-image>"
vm_custom_image_rg_name = "<my-custom-image-resource-group-name>"
``

## Custom startup script

While this is not recommended, this module supports the ability to use your own custom startup script to install. `var.custom_startup_script_template` # defaults to /templates/custom_data.sh.tpl

- The script must exist in a folder named ./templates within your current working directory that you are running Terraform from.
- The script must contain all of the variables (denoted by ${example-variable}) in the module-level startup script
- *Use at your own peril*

By default, the `templates/nomad_custom_data.sh.tpl` script will attempt to install the required software dependencies:

- `azcli` (and `unzip`, a dependency for installing it)
- `nomad`

If your Nomad instances won’t have egress connectivity to official package repositories, you should pre-bake these dependencies into your custom AMI.
