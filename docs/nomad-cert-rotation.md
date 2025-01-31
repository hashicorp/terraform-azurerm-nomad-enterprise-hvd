# Nomad Certificate Rotation

One of the prerequisites for automating Nomad deployment is to store base64-encoded strings of your Nomad TLS certificate and private key files (in PEM format) as secrets in Azure Key Vault. The Nomad client and server `cloud-init` scripts (or equivalent user-data scripts) are designed to retrieve the latest values of these secrets when they run. Therefore, to update Nomad's TLS certificates, update the corresponding secrets in Azure Key Vault, then restart or replace the Nomad servers or clients to pick up the new certificates. Follow the steps below for detailed instructions.

## Secrets

| Certificate file    | Azure Key Vault secret          |
|---------------------|----------------------------------|
| Nomad TLS certificate | `nomad-tls-cert-secret`         |
| Nomad TLS private key | `nomad-tls-privkey-secret`      |

## Procedure

Follow these steps to rotate the certificates for your Nomad cluster.

1. Obtain your new Nomad TLS certificate file and private key file, both in PEM format.

2. Update the values of the existing secrets in Azure Key Vault (`nomad-tls-cert-secret` and `nomad-tls-privkey-secret`, respectively). If you need to base64-encode the files into strings before updating the secrets, see the examples below:

    On Linux (bash):

    ```sh
    cat new_nomad_cert.pem | base64 -w 0
    cat new_nomad_privkey.pem | base64 -w 0
    ```

    On macOS (terminal):

    ```sh
    cat new_nomad_cert.pem | base64
    cat new_nomad_privkey.pem | base64
    ```

    On Windows (PowerShell):

    ```powershell
    function ConvertTo-Base64 {
    param (
        [Parameter(Mandatory=$true)]
        [string]$InputString
    )
    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($InputString)
    $EncodedString = [Convert]::ToBase64String($Bytes)
    return $EncodedString
    }

    Get-Content new_nomad_cert.pem -Raw | ConvertTo-Base64 -Width 0
    Get-Content new_nomad_privkey.pem -Raw | ConvertTo-Base64 -Width 0
    ```

    > **Note:**
    > When updating the values of an Azure Key Vault secret, the secret URI does not change, so **no action should be needed** in terms of updating any configuration values. If the secret URIs **do** change for any reason, you will need to update the following Nomad configuration values with the new URIs and restart Nomad servers or clients:
    >
    >```hcl
    >nomad_tls_cert_keyvault_secret_id    = "<new-nomad-tls-cert-secret-uri>"
    >nomad_tls_privkey_keyvault_secret_id = "<new-nomad-tls-privkey-secret-uri>"
    >```

3. During a maintenance window, restart or replace the Nomad servers and clients. This will trigger the Nomad instances to re-read the updated secrets from Azure Key Vault and apply the new certificates.

   - For instances managed by autoscaling or orchestration, terminate the running instances. This will trigger the creation of new instances that will pull the latest secrets, re-apply the certificates, and rejoin the cluster.
   - For manual or managed deployments, restart the Nomad services (`nomad agent -config=/etc/nomad.d`) to load the new certificates.

By following these steps, your Nomad cluster will seamlessly apply the updated TLS certificates and ensure secure communication.