#!/usr/bin/env bash
# Unified setup: optional DKMS install and user service/timer setup.
set -euo pipefail

usage() {
  echo "Usage: $0 [--with-kmod] [--no-enable] [--time HH:MM]"
  echo "  --no-enable   Do not enable/start the timer, just install units"
  echo "  --time HH:MM  Set daily reminder time (24h format)"
}

ENABLE_TIMER=1
USER_TIME=""
for arg in "$@"; do
  case "$arg" in
    --no-enable) ENABLE_TIMER=0 ;;
    --time)
      echo "Error: --time requires a value (HH:MM)."; usage; exit 1 ;;
    -h|--help) usage; exit 0 ;;
    *)
      if [[ "$arg" =~ ^--time=([0-9]{2}):([0-9]{2})$ ]]; then
        USER_TIME="${BASH_REMATCH[1]}:${BASH_REMATCH[2]}"
      else
        echo "Unknown option: $arg"; usage; exit 1
      fi ;;
  esac
done

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
USER_SYSTEMD_DIR="$HOME/.config/systemd/user"
SERVICE_NAME="coffee-reminder.service"
TIMER_NAME="coffee-reminder.timer"

mkdir -p "$USER_SYSTEMD_DIR"
cp -f "$REPO_DIR/systemd/$SERVICE_NAME" "$USER_SYSTEMD_DIR/$SERVICE_NAME"
cp -f "$REPO_DIR/systemd/$TIMER_NAME" "$USER_SYSTEMD_DIR/$TIMER_NAME"
chmod +x "$REPO_DIR/coffee_reminder.sh"

# If a time was provided, update OnCalendar in the user timer unit.
if [[ -n "$USER_TIME" ]]; then
  # Basic range validation for HH and MM
  HH="${USER_TIME%%:*}"; MM="${USER_TIME##*:}"
  if ((10#$HH < 0 || 10#$HH > 23 || 10#$MM < 0 || 10#$MM > 59)); then
    echo "Invalid time: $USER_TIME. Expected HH:MM in 24h range."; exit 1
  fi
  # Replace OnCalendar line to use provided time.
  sed -i -E "s|^OnCalendar=.*$|OnCalendar=*-*-* ${USER_TIME}:00|" "$USER_SYSTEMD_DIR/$TIMER_NAME"
  echo "Set reminder time to $USER_TIME (daily)."
fi

systemctl --user daemon-reload
if [[ "$ENABLE_TIMER" -eq 1 ]]; then
  systemctl --user enable --now "$TIMER_NAME"
  systemctl --user restart "$TIMER_NAME" || true
fi

echo "Setup complete."
if [[ -n "$USER_TIME" ]]; then
  echo "Effective schedule: $(grep -E '^OnCalendar=' "$USER_SYSTEMD_DIR/$TIMER_NAME" | sed 's/OnCalendar=//')"
fi
echo "Check timers: systemctl --user list-timers | grep coffee-reminder"
