# Coffee Reminder

Introduction
- Coffee Reminder is a simple daily reminder. It runs as a user-level systemd timer and service that shows a desktop notification and can play a sound. Optionally, a kernel module (via DKMS) can beep the PC speaker at the alarm time.

Usage
- On login, the user systemd timer `coffee-reminder.timer` triggers the service `coffee-reminder.service` at the configured time.
- The service executes `coffee_reminder.sh`, which displays a notification and plays a sound if available.
- Optional kernel module support enables a PC speaker beep at the reminder time.

Install
- Dependencies:
  - User service: systemd user services enabled. For desktop notifications and audio, ensure a notification daemon (e.g., libnotify) and an audio player (e.g., paplay/aplay) are present.
  - Kernel module (optional): dkms, kernel headers, make, gcc.
    - Fedora: `sudo dnf install kernel-devel-$(uname -r) dkms make gcc`
    - Ubuntu/Debian: `sudo apt install dkms build-essential linux-headers-$(uname -r)`

- Quick setup (user units, optionally kernel module):
  - Install user service and enable timer, plus DKMS module: `./setup.sh --with-kmod`
  - Install user service and enable timer only: `./setup.sh`
  - Install user service without enabling/starting the timer: `./setup.sh --no-enable`

- DKMS install only:
  - `sudo ./install-kmod.sh`
  - Registers sources under `/usr/src/coffee_reminder-1.0`, runs `dkms add/build/install`, and configures autoload via `/etc/modules-load.d/coffee_reminder.conf`.

Configuration
- Default reminder time is defined by `OnCalendar` in the user timer at `~/.config/systemd/user/coffee-reminder.timer` (initially copied from `systemd/coffee-reminder.timer`).
- To change the time:
  - Edit `~/.config/systemd/user/coffee-reminder.timer` and update `OnCalendar`.
  - Apply changes: `systemctl --user daemon-reload` and `systemctl --user restart coffee-reminder.timer`.
- Custom sound:
  - Set env var `COFFEE_REMINDER_SOUND` to a file path, or place `alarm.(wav|ogg|mp3)` in `~/.local/share/coffee-reminder`.

Verify
- List timers: `systemctl --user list-timers | grep coffee-reminder`
- Trigger immediately: `systemctl --user start coffee-reminder.service`
- If kernel module is installed, sysfs should expose:
  - `/sys/kernel/coffee_reminder/schedule`
  - `/sys/kernel/coffee_reminder/enabled`
  - `/sys/kernel/coffee_reminder/beep_ms`

Uninstall
- Disable the user timer/service:
  - `systemctl --user disable --now coffee-reminder.timer`
- Remove user units:
  - `rm ~/.config/systemd/user/coffee-reminder.service ~/.config/systemd/user/coffee-reminder.timer`
  - `systemctl --user daemon-reload`
- Remove DKMS kernel module (if installed):
  - `sudo dkms remove coffee_reminder/1.0 --all`
  - `sudo rm -rf /usr/src/coffee_reminder-1.0`
  - `sudo rm -f /etc/modules-load.d/coffee_reminder.conf`

Notes
- `setup.sh`:
  - Copies units from `systemd/` to `~/.config/systemd/user/`.
  - Marks `coffee_reminder.sh` executable.
  - Reloads user systemd and enables/starts the timer unless `--no-enable` is used.
  - With `--with-kmod`, invokes kernel module install (requiring sudo/root).
- DKMS will rebuild the module for new kernels automatically.
- The user service continues to work even if the kernel module is not present.

License
- GPLv2. See COPYING for the full text.
