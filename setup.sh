#!/usr/bin/env bash
# Unified setup: optional DKMS install and user service/timer setup.
set -euo pipefail

usage() {
  echo "Usage: $0 [--with-kmod] [--no-enable]"
  echo "  --with-kmod   Install kernel module via DKMS (requires sudo)"
  echo "  --no-enable   Do not enable/start the timer, just install units"
}

WITH_KMOD=0
ENABLE_TIMER=1
for arg in "$@"; do
  case "$arg" in
    --with-kmod) WITH_KMOD=1 ;;
    --no-enable) ENABLE_TIMER=0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg"; usage; exit 1 ;;
  esac
done

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
USER_SYSTEMD_DIR="$HOME/.config/systemd/user"
SERVICE_NAME="coffee-reminder.service"
TIMER_NAME="coffee-reminder.timer"

if [[ "$WITH_KMOD" -eq 1 ]]; then
  if [[ $EUID -ne 0 ]]; then
    echo "Installing kernel module via DKMS requires sudo/root. Re-running with sudo..."
    exec sudo "$REPO_DIR/install-kmod.sh"
  else
    "$REPO_DIR/install-kmod.sh"
  fi
fi

mkdir -p "$USER_SYSTEMD_DIR"
cp -f "$REPO_DIR/systemd/$SERVICE_NAME" "$USER_SYSTEMD_DIR/$SERVICE_NAME"
cp -f "$REPO_DIR/systemd/$TIMER_NAME" "$USER_SYSTEMD_DIR/$TIMER_NAME"
chmod +x "$REPO_DIR/coffee_reminder.sh"

systemctl --user daemon-reload
if [[ "$ENABLE_TIMER" -eq 1 ]]; then
  systemctl --user enable --now "$TIMER_NAME"
  systemctl --user restart "$TIMER_NAME" || true
fi

echo "Setup complete."
echo "Check timers: systemctl --user list-timers | grep coffee-reminder"
