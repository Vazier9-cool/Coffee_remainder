#!/usr/bin/env bash
# Installer for Coffee Reminder as a user-level systemd service and timer.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
USER_SYSTEMD_DIR="$HOME/.config/systemd/user"
SERVICE_NAME="coffee-reminder.service"
TIMER_NAME="coffee-reminder.timer"

mkdir -p "$USER_SYSTEMD_DIR"

# Copy units (force overwrite)
cp -f "$REPO_DIR/systemd/$SERVICE_NAME" "$USER_SYSTEMD_DIR/$SERVICE_NAME"
cp -f "$REPO_DIR/systemd/$TIMER_NAME" "$USER_SYSTEMD_DIR/$TIMER_NAME"

# Ensure script is executable
chmod +x "$REPO_DIR/coffee_reminder.sh"

# Reload and enable timer
systemctl --user daemon-reload
systemctl --user enable --now "$TIMER_NAME"
systemctl --user restart "$TIMER_NAME"

echo "Installed. Check status with: systemctl --user list-timers | grep coffee-reminder"
echo "Unit content:"; echo; sed -n '1,200p' "$USER_SYSTEMD_DIR/$TIMER_NAME"
