# Deployment customizations

This page contains various deployment customizations related to creating your Nomad infrastructure and their corresponding module input variables that you may configure to meet your specific requirements where the default module values do not suffice. All of the module input variables mentioned on this page are optional.

## Custom VM image

By default, this module will use the standard marketplace image based on the value of the `vm_image_offer` input (either `ubuntu` or `rhel`). If you prefer to use your own custom VM image, you can set `vm_custom_image_name` accordingly.

To use a custom VM image, you can specify it using the following module input variables:

```hcl
vm_image_offer = "UbuntuServer"
vm_custom_image_name   = "<custom-rhel-ami-id>"
```

By default, the `templates/install_nomad.sh.tpl` script will attempt to install the required software dependencies:

- `azcli` (and `unzip`, a dependency for installing it)
- `nomad` 

If your Nomad EC2 instances won’t have egress connectivity to official package repositories, you should pre-bake these dependencies into your custom AMI.
