#!/usr/bin/env bash
# Coffee reminder script: logs, shows desktop notification, plays TTS or custom sound
set -euo pipefail

LOG_DIR="$HOME/.local/share/coffee-reminder"
LOG_FILE="$LOG_DIR/log.txt"
mkdir -p "$LOG_DIR"

# Reminder message
message="Hey! It's your coffee time ☕ Take a short break and enjoy a cup."

# Log the reminder
now_ts="$(date '+%Y-%m-%d %H:%M:%S')"
printf "%s - %s\n" "$now_ts" "$message" >> "$LOG_FILE"

# Desktop notification
if command -v notify-send >/dev/null 2>&1; then
  notify-send "Coffee Reminder" "$message" || true
fi

# Custom audio file support
CUSTOM_SOUND="${COFFEE_REMINDER_SOUND:-}"
if [ -z "$CUSTOM_SOUND" ]; then
  for f in "$LOG_DIR"/alarm.wav "$LOG_DIR"/alarm.ogg "$LOG_DIR"/alarm.mp3; do
    if [ -f "$f" ]; then CUSTOM_SOUND="$f"; break; fi
  done
fi

play_custom_sound() {
  local f="$1"
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

# Text-to-speech: speak message directly once
speak_message() {
  if command -v espeak >/dev/null 2>&1; then
    espeak -s 140 "$message" >/dev/null 2>&1
    return 0
  elif command -v spd-say >/dev/null 2>&1; then
    spd-say "$message" || true
    return 0
  else
    return 1
  fi
}

# Main logic: custom sound > TTS > fallback alarm
if [ -n "$CUSTOM_SOUND" ] && [ -f "$CUSTOM_SOUND" ]; then
  play_custom_sound "$CUSTOM_SOUND" || true
elif speak_message; then
  # TTS already spoken once
  :
else
  # Fallback desktop/alarm sounds
  if command -v canberra-gtk-play >/dev/null 2>&1; then
    for i in 1 2 3; do
      canberra-gtk-play -i alarm-clock || canberra-gtk-play -i bell || true
      sleep 3
    done
  else
    ALARM_OGA="/usr/share/sounds/freedesktop/stereo/alarm-clock.oga"
    ALARM_WAV="/usr/share/sounds/freedesktop/stereo/bell.oga"
    if command -v paplay >/dev/null 2>&1 && [ -f "$ALARM_OGA" ]; then
      for i in 1 2 3; do paplay "$ALARM_OGA" || true; sleep 0.7; done
    elif command -v aplay >/dev/null 2>&1 && [ -f "$ALARM_WAV" ]; then
      for i in 1 2 3; do aplay "$ALARM_WAV" >/dev/null 2>&1 || true; sleep 0.7; done
    else
      printf "\a" || true
      if command -v beep >/dev/null 2>&1; then
        beep -f 1200 -l 250 -r 3 || true
      elif command -v speaker-test >/dev/null 2>&1; then
        (speaker-test -t sine -f 600 -l 1 >/dev/null 2>&1 & pid=$!; sleep 2; kill "$pid" 2>/dev/null || true)
      fi
    fi
  fi
fi

# Print reminder to terminal
echo "$message"

