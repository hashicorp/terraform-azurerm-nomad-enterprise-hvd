# Nomad Enterprise HVD - client example

This example will deploy Nomad clients to join an existing Nomad Cluster. The clients can join via specified DNS/IP addresses using the `nomad_upstream_servers` variable or other configurations like custom TLS settings for secure communication.

Runtimes are not enabled by default. To enable a runtime, modify the `install_runtime` function in the `templates\nomad_custom_data.sh.tpl` with the code to enable any runtimes as needed.
