# Deployment customizations

This page contains various deployment customizations related to creating your Nomad infrastructure and their corresponding module input variables that you may configure to meet your specific requirements where the default module values do not suffice. All of the module input variables mentioned on this page are optional.


## Custom VM Image

If a custom VM image is preferred over using a standard marketplace image, the following variables may be set:

```hcl
vm_custom_image_name    = "<my-custom-ubuntu-2204-image>"
vm_custom_image_rg_name = "<my-custom-image-resource-group-name>"
``

## custom template

By default, the `templates/install_nomad.sh.tpl` script will attempt to install the required software dependencies:

- `azcli` (and `unzip`, a dependency for installing it)
- `nomad`

If your Nomad EC2 instances won’t have egress connectivity to official package repositories, you should pre-bake these dependencies into your custom AMI.
