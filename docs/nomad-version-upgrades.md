# Nomad version upgrades

Nomad follows a regular release cadence. See the [Nomad Releases](https://developer.hashicorp.com/nomad/docs/v1.8.x/release-notes) page for full details on the releases. Nomad upgrades are designed to be flexible, with two primary strategies: in-place upgrades, where the Nomad binary is updated without disrupting running allocations, and rolling upgrades, where new instances with the updated version replace old ones. To upgrade, update your Terraform code to reflect the new version, apply the changes to update the Azure VM scale set configuration, and replace or upgrade the VMs. Perform these steps during a maintenance window to ensure minimal disruption to workloads.

This module includes an input variable named `nomad_version` that dictates which version of Nomad is deployed.

## Procedure

1. Determine your desired version of Nomad from the [Nomad Upgrades](https://developer.hashicorp.com/nomad/docs/upgrade) page. The value you need will be in the **Version** column of the table.

1. During a maintenance window, connect to your existing Nomad servers and gracefully drain them to ensure no new jobs are scheduled.

    To gracefully drain the node:

    ```sh
    nomad node drain -self -yes
    ```

    For more details on this command, see the following documentation:

    - [Nomad Node Drain](https://developer.hashicorp.com/nomad/docs/commands/node/drain)

1. Generate a backup of your backend data (e.g. Consul, Vault, or other backends used).

1. Update the value of the `nomad_version` input variable within your `terraform.tfvars` file to the desired Nomad version.

    ```hcl
    nomad_version = "1.8.0"
    ```
   > 📝 **Note:** Nomad does not support downgrading at this time. Downgrading clients requires draining allocations and removing the data directory. Downgrading servers safely requires re-provisioning the cluster.

1. From within the directory managing your Nomad deployment, run `terraform apply` to update the VM scale set configuration.

1. Use the Azure Portal or Azure CLI to initiate a rolling upgrade on the Virtual Machine Scale Set. This will create new VMs with the updated configuration, effectively re-installing Nomad with the specified version (`nomad_version`).

    For example, using the Azure CLI:

    ```sh
    az vmss update-instances --name <vmss-name> --resource-group <resource-group-name>
    ```

    Replace `<vmss-name>` with your Virtual Machine Scale Set name and `<resource-group-name>` with the resource group containing the scale set.

1. Verify the upgrade by connecting to one of the new VMs and checking the installed Nomad version:

    ```sh
    nomad --version
    ```

1. Once the new Nomad version is verified, remove any old VMs manually if not automatically handled by the scale set upgrade process.
