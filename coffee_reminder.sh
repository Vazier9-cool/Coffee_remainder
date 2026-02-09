#!/usr/bin/env bash
# Coffee reminder script: logs and optionally shows a desktop notification.
set -euo pipefail

LOG_DIR="$HOME/.local/share/coffee-reminder"
LOG_FILE="$LOG_DIR/log.txt"
mkdir -p "$LOG_DIR"

now_ts="$(date '+%Y-%m-%d %H:%M:%S')"
message="Daily reminder: Time to check your caffeine intake. Keep it under 300mg today."

printf "%s - %s\n" "$now_ts" "$message" >> "$LOG_FILE"

# Try desktop notification
if command -v notify-send >/dev/null 2>&1; then
  notify-send "Coffee Reminder" "$message" || true
fi

# If a custom audio file is provided, prefer it.
# You can set COFFEE_REMINDER_SOUND to a file path, or place a file named alarm.(wav|ogg|mp3) in $LOG_DIR.
CUSTOM_SOUND="${COFFEE_REMINDER_SOUND:-}"
if [ -z "$CUSTOM_SOUND" ]; then
  # pick first matching file if present
  for f in "$LOG_DIR"/alarm.wav "$LOG_DIR"/alarm.ogg "$LOG_DIR"/alarm.mp3; do
    if [ -f "$f" ]; then CUSTOM_SOUND="$f"; break; fi
  done
fi

play_custom_sound() {
  local f="$1"
  # Try PulseAudio/PipeWire players first
  if command -v paplay >/dev/null 2>&1; then
    paplay "$f" || true
  elif command -v aplay >/dev/null 2>&1; then
    aplay "$f" >/dev/null 2>&1 || true
  elif command -v ffplay >/dev/null 2>&1; then
    ffplay -nodisp -autoexit -loglevel error "$f" >/dev/null 2>&1 || true
  elif command -v mpg123 >/dev/null 2>&1; then
    mpg123 -q "$f" || true
  else
    return 1
  fi
}

if [ -n "$CUSTOM_SOUND" ] && [ -f "$CUSTOM_SOUND" ]; then
  # Play custom sound 2 times
  for i in 1 2; do play_custom_sound "$CUSTOM_SOUND" || true; sleep 0.7; done
else
  # Alarm sound (prefer themed desktop sounds)
  # Try canberra-gtk-play (PulseAudio/PipeWire)
  if command -v canberra-gtk-play >/dev/null 2>&1; then
    # Play a recognizable alarm sound 3 times
    for i in 1 2 3; do
      canberra-gtk-play -i alarm-clock || canberra-gtk-play -i bell || true
      sleep 0.7
    done
  else
    # Try freedesktop sound files via paplay/aplay
    ALARM_OGA="/usr/share/sounds/freedesktop/stereo/alarm-clock.oga"
    ALARM_WAV="/usr/share/sounds/freedesktop/stereo/bell.oga"
    if command -v paplay >/dev/null 2>&1 && [ -f "$ALARM_OGA" ]; then
      for i in 1 2 3; do paplay "$ALARM_OGA" || true; sleep 0.7; done
    elif command -v aplay >/dev/null 2>&1 && [ -f "$ALARM_WAV" ]; then
      for i in 1 2 3; do aplay "$ALARM_WAV" >/dev/null 2>&1 || true; sleep 0.7; done
    else
      # Fallbacks
      printf "\a" || true
      if command -v beep >/dev/null 2>&1; then
        beep -f 1200 -l 250 -r 3 || true
      elif command -v speaker-test >/dev/null 2>&1; then
        (speaker-test -t sine -f 600 -l 1 >/dev/null 2>&1 & pid=$!; sleep 2; kill "$pid" 2>/dev/null || true)
      fi
    fi
  fi
fi

echo "$message"
