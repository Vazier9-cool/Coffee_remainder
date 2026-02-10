# Coffee Reminder

Introduction
- Coffee Reminder is a simple daily reminder. It runs as a user-level systemd timer and service that shows a desktop notification and can play a sound.

Usage
- On login, the user systemd timer `coffee-reminder.timer` triggers the service `coffee-reminder.service` at the configured time.
- The service executes `coffee_reminder.sh`, which displays a notification and plays a sound if available.

Install
- Dependencies:
  - User service: systemd user services enabled. For desktop notifications and audio, ensure a notification daemon (e.g., libnotify) and an audio player (e.g., paplay/aplay) are present.

- Quick setup (user units, optionally kernel module):
  - Install user service and enable timer only: `./setup.sh`
  - Install user service without enabling/starting the timer: `./setup.sh --no-enable`
  - Install and set custom time: `./setup.sh --time=HH:MM` (24h)
    - Example: `./setup.sh --time=08:30`

Configuration
- Default reminder time comes from `systemd/coffee-reminder.timer` (OnCalendar).
- To change time after setup:
  - Edit `~/.config/systemd/user/coffee-reminder.timer` and update `OnCalendar`.
  - Apply changes: `systemctl --user daemon-reload` and `systemctl --user restart coffee-reminder.timer`.
- Custom sound:
  - Set env var `COFFEE_REMINDER_SOUND` to a file path, or place `alarm.(wav|ogg|mp3)` in `~/.local/share/coffee-reminder`.

Verify
- List timers: `systemctl --user list-timers | grep coffee-reminder`
- Trigger immediately: `systemctl --user start coffee-reminder.service`

Uninstall
- Disable the user timer/service:
  - `systemctl --user disable --now coffee-reminder.timer`
- Remove user units:
  - `rm ~/.config/systemd/user/coffee-reminder.service ~/.config/systemd/user/coffee-reminder.timer`
  - `systemctl --user daemon-reload`

Notes
- `setup.sh`:
  - Copies units from `systemd/` to `~/.config/systemd/user/`.
  - Marks `coffee_reminder.sh` executable.
  - Can set custom time via `--time=HH:MM` by updating `OnCalendar` in your user timer.
  - Reloads user systemd and enables/starts the timer unless `--no-enable` is used.
  - With `--with-kmod`, invokes kernel module install (requiring sudo/root).

License
- GPLv2. See COPYING for the full text.
