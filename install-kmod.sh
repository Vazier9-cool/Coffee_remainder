#!/usr/bin/env bash
# Install coffee_reminder kernel module using DKMS.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$REPO_DIR/src"
MODULE_NAME="coffee_reminder"
MODULE_VERSION="1.0"
DKMS_SRC_DIR="/usr/src/${MODULE_NAME}-${MODULE_VERSION}"

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root (sudo)."
  exit 1
fi

# Check for dkms
if ! command -v dkms >/dev/null 2>&1; then
  echo "DKMS not found. Install dkms (e.g., sudo dnf install dkms or apt install dkms)."
  exit 1
fi

# Prepare DKMS source directory
rm -rf "$DKMS_SRC_DIR"
mkdir -p "$DKMS_SRC_DIR"

# Copy sources (including dkms.conf)
cp -r "$SRC_DIR/"* "$DKMS_SRC_DIR/"

# Add, build, and install via DKMS
set -x

dkms remove ${MODULE_NAME}/${MODULE_VERSION} --all || true

dkms add ${MODULE_NAME}/${MODULE_VERSION}
dkms build ${MODULE_NAME}/${MODULE_VERSION}
dkms install ${MODULE_NAME}/${MODULE_VERSION}
set +x

# Ensure the module loads at boot
echo "${MODULE_NAME}" > /etc/modules-load.d/${MODULE_NAME}.conf || true

# Load module now
modprobe ${MODULE_NAME} || true

echo "Installed via DKMS. Sysfs: /sys/kernel/${MODULE_NAME}/{schedule,enabled,beep_ms}"
echo "Module will rebuild automatically on kernel updates."
