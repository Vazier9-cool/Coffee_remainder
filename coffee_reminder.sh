#!/usr/bin/env bash
# Coffee reminder script: logs and optionally shows a desktop notification.
set -euo pipefail

LOG_DIR="$HOME/.local/share/coffee-reminder"
LOG_FILE="$LOG_DIR/log.txt"
mkdir -p "$LOG_DIR"

now_ts="$(date '+%Y-%m-%d %H:%M:%S')"
message="Time to check your caffeine intake. Keep it under 300mg today."

printf "%s - %s\n" "$now_ts" "$message" >> "$LOG_FILE"

if command -v notify-send >/dev/null 2>&1; then
  notify-send "Coffee Reminder" "$message" || true
fi

echo "$message"
