#!/usr/bin/env bash
set -euo pipefail

LOGFILE="/var/log/nomad-cloud-init.log"
SYSTEMD_DIR="/etc/systemd/system"
NOMAD_DIR_CONFIG="/etc/nomad.d"
NOMAD_CONFIG_PATH="$NOMAD_DIR_CONFIG/nomad.hcl"
NOMAD_DIR_TLS="/etc/nomad.d/tls"
NOMAD_DIR_DATA="/opt/nomad/data"
NOMAD_DIR_LICENSE="/opt/nomad/license"
NOMAD_LICENSE_PATH="$NOMAD_DIR_LICENSE/license.hclic"
NOMAD_DIR_ALLOC_MOUNTS="/opt/nomad/alloc_mounts"
NOMAD_DIR_LOGS="/var/log/nomad"
NOMAD_DIR_BIN="/usr/bin"
CNI_DIR_BIN="/opt/cni/bin"
NOMAD_USER="nomad"
NOMAD_GROUP="nomad"
NOMAD_INSTALL_URL="${nomad_install_url}"
CNI_INSTALL_URL="${cni_install_url}"
REQUIRED_PACKAGES="curl jq unzip"
ADDITIONAL_PACKAGES="${additional_package_names}"

NOMAD_TLS_CERT_SECRET_ID="${nomad_tls_cert_secret_id}"
NOMAD_TLS_PRIVKEY_SECRET_ID="${nomad_tls_privkey_secret_id}"
NOMAD_TLS_CA_BUNDLE_SECRET_ID="${nomad_tls_ca_bundle_secret_id}"
NOMAD_LICENSE_SECRET_ID="${nomad_license_secret_id}"
NOMAD_GOSSIP_ENCRYPTION_KEY_ID="${nomad_gossip_encryption_key_secret_id}"
NOMAD_TLS_ENABLED="${nomad_tls_enabled}"
NOMAD_ACL_ENABLED="${nomad_acl_enabled}"
NOMAD_CLIENT="${nomad_client}"
NOMAD_SERVER="${nomad_server}"
NOMAD_DATACENTER="${nomad_datacenter}"
NOMAD_LOCATION="${nomad_location}"
NOMAD_UI_ENABLED="${nomad_ui_enabled}"
NOMAD_NODES="${nomad_nodes}"
AUTOPILOT_HEALTH_ENABLED="${autopilot_health_enabled}"


function log {
    local level="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local log_entry="$timestamp [$level] - $message"

    echo "$log_entry" | tee -a "$LOGFILE"
}

function detect_os_distro {
    local OS_DISTRO_NAME=$(grep "^NAME=" /etc/os-release | cut -d'"' -f2)
    local OS_DISTRO_DETECTED

    case "$OS_DISTRO_NAME" in
    "Ubuntu"*)
        OS_DISTRO_DETECTED="ubuntu"
        ;;
    "CentOS"*)
        OS_DISTRO_DETECTED="centos"
        ;;
    "Red Hat"*)
        OS_DISTRO_DETECTED="rhel"
        ;;
    "Debian"*)
        OS_DISTRO_DETECTED="debian"
        ;;
    *)
        log "ERROR" "Unsupported Linux OS distro: '$OS_DISTRO_NAME'. Exiting."
        exit 1
        ;;
    esac

    echo "$OS_DISTRO_DETECTED"
}

function prepare_disk() {
    local device_name=$(readlink -f /dev/disk/azure/scsi1/lun0)
    log "DEBUG" "prepare_disk - device_name; $device_name"

    local mount_point="$1"
    log "DEBUG" "prepare_disk - device_mountpoint; $${mount_point}"

    local label="$2"
    log "DEBUG" "prepare_disk - device_label; $${label}"

    mkdir -p $mount_point
    log "DEBUG" "mountpoint created; $${mount_point}"

    sudo wipefs --all $device_name
    sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0 -L $label $${device_name}
    log "DEBUG" "Format complete; $${device_name}"

    grep -q "LABEL=$label $mount_point ext4 defaults 0 2" /etc/fstab || echo "LABEL=$label $mount_point ext4 defaults 0 2" >> /etc/fstab

    sudo mount -a

}

function install_prereqs {
    local OS_DISTRO="$1"
    log "INFO" "Installing required packages..."

    if [[ "$OS_DISTRO" == "ubuntu" || "$OS_DISTRO" == "debian" ]]; then
        apt-get update -y
        apt-get install -y $REQUIRED_PACKAGES $ADDITIONAL_PACKAGES
    elif [[ "$OS_DISTRO" == "centos" || "$OS_DISTRO" == "rhel" ]]; then
        yum install -y $REQUIRED_PACKAGES $ADDITIONAL_PACKAGES
    else
        log "ERROR" "Unsupported package manager for OS distro: '$OS_DISTRO'. Exiting."
        exit 1
    fi
}

function install_azcli {
  local os_distro="$1"

  if [[ -n "$(command -v az)" ]]; then
    log "INFO" "Detected 'az' (azure-cli) is already installed. Skipping."
  else
    if [[ "$os_distro" == "ubuntu" ]]; then
      log "INFO" "Installing Azure CLI for Ubuntu."
      curl -sL https://aka.ms/InstallAzureCLIDeb | bash
    elif [[ "$os_distro" == "centos" ]] || [[ "$os_distro" == "rhel" ]]; then
      log "INFO" "Installing Azure CLI for CentOS/RHEL."
      rpm --import https://packages.microsoft.com/keys/microsoft.asc
      cat > /etc/yum.repos.d/azure-cli.repo << EOF
[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
      dnf install -y azure-cli
    fi
  fi
  log "INFO" "Attempting Azure login using Managed Identity..."
  if az login --identity &>/dev/null; then
    log "INFO" "Azure login successful."
  else
    log "ERROR" "Azure login failed! Ensure the VM has a Managed Identity."
    exit 1
  fi
}

function scrape_vm_info {
    log "INFO" "Scraping Azure VM metadata."

    INSTANCE_ID=$(curl -s -H "Metadata:true" --noproxy "*" "http://169.254.169.254/metadata/instance/compute/vmId?api-version=2021-02-01&format=text")
    LOCATION=$(curl -s -H "Metadata:true" --noproxy "*" "http://169.254.169.254/metadata/instance/compute/location?api-version=2021-02-01&format=text")
    RESOURCE_GROUP=$(curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance/compute/resourceGroupName?api-version=2021-02-01&format=text")
    VMSS_NAME=$(curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance/compute/vmScaleSetName?api-version=2021-02-01&format=text")

    log "INFO" "VM ID: $INSTANCE_ID, Location: $LOCATION, Resource Group: $RESOURCE_GROUP, VMSS Name: $VMSS_NAME."
}

# For Nomad there are a number of supported runtimes, including Exec, Docker, Podman, raw_exec, and more. This function should be modified 
# to install the runtime that is appropriate for your environment. By default the no runtimes will be enabled. 
function install_runtime {
    log "INFO" "Installing a runtime..."
    log "INFO" "Done installing runtime."
}

function retrieve_secret {
    local secret_id="$1"
    local destination="$2"

    if [[ "$secret_id" == "NONE" ]]; then
        log "INFO" "No secret to retrieve for $destination."
        return
    fi

    log "INFO" "Retrieving secret $secret_id for $destination."
    az keyvault secret show --id "$secret_id" --query value -o tsv | base64 -d > "$destination"
}

function retrieve_license {
    local secret_id="$1"

    if [[ "$secret_id" == "NONE" ]]; then
        log "INFO" "No license to retrieve."
        return
    fi

    log "INFO" "Retrieving license."
    NOMAD_LICENSE=$(az keyvault secret show --id "$secret_id" --query value -o tsv)
    echo "$NOMAD_LICENSE" >$NOMAD_LICENSE_PATH
}

function retrieve_gossip_key {
    local secret_id="$1"

    if [[ "$secret_id" == "NONE" ]]; then
        log "INFO" "No gossip key to retrieve."
        return
    fi

    log "INFO" "Retrieving gossip key."
    GOSSIP_ENCRYPTION_KEY=$(az keyvault secret show --id "$secret_id" --query value -o tsv)
}

function create_user_and_group {
    log "INFO" "Creating Nomad user and group."

    sudo groupadd --system $NOMAD_GROUP
    sudo useradd --system --no-create-home -d $NOMAD_DIR_CONFIG -g $NOMAD_GROUP $NOMAD_USER

    log "INFO" "Nomad user and group created."
}

function create_directories {
    log "INFO" "Creating required directories for Nomad."

    directories=(
        "$NOMAD_DIR_CONFIG"
        "$NOMAD_DIR_TLS"
        "$NOMAD_DIR_DATA"
        "$NOMAD_DIR_ALLOC_MOUNTS"
        "$NOMAD_DIR_LICENSE"
        "$NOMAD_DIR_LOGS"
        "$NOMAD_DIR_BIN"
        "$CNI_DIR_BIN"
        "$NOMAD_DIR_ALLOC_MOUNTS"
    )

    for dir in "$${directories[@]}"; do
        mkdir -p "$dir"
        chown "$NOMAD_USER:$NOMAD_GROUP" "$dir"
        chmod 755 "$dir"
    done

    log "INFO" "Required directories created."
}

function install_cni_plugins {
    log "INFO" "Installing CNI plugins..."

    # Download the CNI plugins
    sudo curl -Lso $CNI_DIR_BIN/cni-plugins.tgz "${cni_install_url}"

    # Untar the CNI plugins
    tar -C $CNI_DIR_BIN -xzf $CNI_DIR_BIN/cni-plugins.tgz
}

function install_nomad {
    log "INFO" "Installing Nomad binary."

    sudo curl -sSLo "$NOMAD_DIR_BIN/nomad.zip" "$NOMAD_INSTALL_URL"
    sudo unzip -o "$NOMAD_DIR_BIN/nomad.zip" -d "$NOMAD_DIR_BIN"
    sudo rm  "$NOMAD_DIR_BIN/nomad.zip"

    log "INFO" "Nomad installation complete."
}

function generate_nomad_config {
  log "INFO" "Generating $NOMAD_CONFIG_PATH file."
  %{ if nomad_server }
    # Read the encryption key from the file
    log "INFO" "Fetching Nomad server private IPs..."
    NOMAD_SERVERS=$(az vmss nic list --resource-group "$RESOURCE_GROUP" --vmss-name "$VMSS_NAME" \
  --query "[].ipConfigurations[0].privateIPAddress" -o tsv | awk '{print "\"" $0 "\""}' | paste -sd "," -)
    NOMAD_SERVERS=$${NOMAD_SERVERS%,}
  %{ endif }

  cat >$NOMAD_CONFIG_PATH <<EOF

# Full configuration options can be found at https://developer.hashicorp.com/nomad/docs/configuration
%{ if nomad_acl_enabled }
acl {
  enabled = true
}%{ endif }

data_dir  = "/opt/nomad/data"
bind_addr = "0.0.0.0"

datacenter = "${nomad_datacenter}"
region     = "${nomad_location}"

# leave_on_interrupt = true
# leave_on_terminate = true

enable_syslog   = true
syslog_facility = "daemon"

%{ if nomad_server }
server {
  enabled          = true

  bootstrap_expect = "${nomad_nodes}"
  license_path     = "$NOMAD_DIR_LICENSE/license.hclic"
  encrypt          = "${GOSSIP_ENCRYPTION_KEY}"

  server_join {
    retry_join = [$NOMAD_SERVERS]
  }
}

%{ if autopilot_health_enabled }
autopilot {
    cleanup_dead_servers      = true
    last_contact_threshold    = "200ms"
    max_trailing_logs         = 250
    server_stabilization_time = "10s"
    enable_redundancy_zones   = true
    disable_upgrade_migration = false
    enable_custom_upgrades    = false
}
%{ endif }
%{ endif }

%{ if nomad_tls_enabled }
tls {
  http      = true
  rpc       = true
  cert_file = "$NOMAD_DIR_TLS/cert.pem" 
  key_file  = "$NOMAD_DIR_TLS/key.pem"
%{ if nomad_tls_ca_bundle_secret_id != "NONE" ~}
  ca_file   = "$NOMAD_DIR_TLS/bundle.pem"
%{ endif ~}
  verify_server_hostname = true
  verify_https_client    = false
}
%{ endif }

%{ if nomad_client }
client {
  enabled = true
%{ if nomad_upstream_servers != null ~}
servers = [
%{ for addr in formatlist("%s",nomad_upstream_servers) ~}
   "${addr}",
%{ endfor ~}
]
%{ else }
  server_join {
    retry_join = [$NOMAD_SERVERS]
  }
%{ endif }
}
%{ endif }

telemetry {
  collection_interval = "1s"
  disable_hostname = true
  prometheus_metrics = true
  publish_allocation_metrics = true
  publish_node_metrics = true
}

ui {
  enabled = ${ nomad_ui_enabled }
}
EOF

  chown $NOMAD_USER:$NOMAD_GROUP $NOMAD_CONFIG_PATH
  chmod 640 $NOMAD_CONFIG_PATH
}

function configure_systemd {
    log "INFO" "Configuring Nomad systemd service."

    cat > "$SYSTEMD_DIR/nomad.service" <<EOF
[Unit]
Description=HashiCorp Nomad
Documentation=https://nomadproject.io/docs/
Wants=network-online.target
After=network-online.target

[Service]
User=$NOMAD_USER
Group=$NOMAD_GROUP
ExecStart=$NOMAD_DIR_BIN/nomad agent -config=$NOMAD_DIR_CONFIG/nomad.hcl
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable nomad

    log "INFO" "Nomad systemd service configured."
}

function start_nomad {
    log "INFO" "Starting Nomad service."

    systemctl start nomad

    log "INFO" "Nomad service started."
}

function exit_script {
  if [[ "$1" == 0 ]]; then
    log "INFO" "nomad_custom_data script finished successfully!"
  else
    log "ERROR" "nomad_custom_data script finished with error code $1."
  fi

  exit "$1"
}

function main {
    log "INFO" "Starting Nomad setup."
    OS_DISTRO=$(detect_os_distro)
    log "INFO" "Detected Linux OS distro is '$OS_DISTRO'."
    scrape_vm_info
    install_prereqs "$OS_DISTRO"
    install_azcli "$OS_DISTRO"
    prepare_disk "/var/lib/nomad" "nomad_data"
    create_user_and_group
    create_directories
    install_nomad
    %{ if nomad_client ~}
    install_runtime
    install_cni_plugins
    %{ endif ~}
    %{ if nomad_server ~}
    log "INFO" "Grabbing Secrets from ${nomad_license_secret_id}."
    retrieve_license "$NOMAD_LICENSE_SECRET_ID" ${nomad_license_secret_id} 
    log "INFO" "Grabbing Secrets from ${nomad_gossip_encryption_key_secret_id}."
    retrieve_gossip_key "$NOMAD_GOSSIP_ENCRYPTION_KEY_ID" ${nomad_gossip_encryption_key_secret_id} 
    %{ endif ~}
    %{ if nomad_tls_enabled ~}
    log "INFO" "is ${nomad_tls_enabled} ?."
    retrieve_secret "$NOMAD_TLS_CERT_SECRET_ID" "$NOMAD_DIR_TLS/cert.pem"
    retrieve_secret "$NOMAD_TLS_PRIVKEY_SECRET_ID" "$NOMAD_DIR_TLS/key.pem"
    %{ if nomad_tls_ca_bundle_secret_id != "NONE" ~}
    retrieve_secret "$NOMAD_TLS_CA_BUNDLE_SECRET_ID" "$NOMAD_DIR_TLS/bundle.pem"
    %{ endif ~}
    chown -R $NOMAD_USER:$NOMAD_GROUP $NOMAD_DIR_TLS
    chmod 640 $NOMAD_DIR_TLS/*pem
    %{ endif ~}
    generate_nomad_config
    configure_systemd
    start_nomad

    exit_script 0

    log "INFO" "Nomad setup completed successfully."
}

main
