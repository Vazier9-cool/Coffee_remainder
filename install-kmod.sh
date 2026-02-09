#!/usr/bin/env bash
# Build and install coffee_reminder kernel module, then load it.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$REPO_DIR/src"
MODULE_NAME="coffee_reminder"

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root (sudo)."
  exit 1
fi

# Ensure kernel headers exist
if [[ ! -d "/lib/modules/$(uname -r)/build" ]]; then
  echo "Kernel headers not found. Install kernel-devel/linux-headers for your kernel."
  exit 1
fi

make -C "$SRC_DIR" clean
make -C "$SRC_DIR" all

# Copy to /lib/modules and update deps
cp "$SRC_DIR/$MODULE_NAME.ko" "/lib/modules/$(uname -r)/"
depmod -a

# Load module
modprobe $MODULE_NAME || insmod "/lib/modules/$(uname -r)/$MODULE_NAME.ko"

echo "Loaded module. Sysfs: /sys/kernel/coffee_reminder/{schedule,enabled,beep_ms}"
# Example usage:
# echo "09:00,12:00,15:00" > /sys/kernel/coffee_reminder/schedule
# echo 1 > /sys/kernel/coffee_reminder/enabled
# echo 1500 > /sys/kernel/coffee_reminder/beep_ms
