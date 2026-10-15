# clockmost-desktop-config

The glue a clockmost Linux desktop needs besides the shell and the skins - what was done by hand on the first metal
install (2026-10-14, workspace `runbooks/desktop-linux-install-log.md`), packaged so a reinstall gets it.

**System (the package):**
- `depends`: the apps the desktop relies on that nothing else pulls in - qt5-wayland (KeePassXC is Qt 5), ffmpeg4.4
  (Spotify local files: libavcodec <= 61), fuse2 (AppImages), tesseract-data-eng (Spectacle OCR), the Zabbix check
  tools, rclone + restic.
- Zabbix desktop checks: `/usr/lib/clockmost-desktop-config/zabbix-desktop-check.sh` + UserParameters in
  `/etc/zabbix/zabbix_agent2.d/clockmost-desktop.conf` (backup file): backup + Drive-sync status, failed units,
  pending updates, btrfs errors, SMART. Internal disks (SATA/NVMe/SAS) and btrfs filesystems are found at run time.
  SMART/btrfs need root -> `clockmost-desktop-health.timer` (every 30 min) collects them into
  `/var/lib/clockmost-health/desktop.status`; the agent only reads (Arch creates the `zabbix` user expired, so sudo
  for it fails). -1 = unreadable/stale, never a silent 0. Zabbix side: clockmost-infra `ops/zabbix/zbx23`.
- journald keeps up to 1G (`/usr/lib/systemd/journald.conf.d/90-clockmost.conf`; CachyOS ships 50M, too little to
  read a crash afterwards).
- `tmpfiles.d`: `/var/lib/clockmost-{health,backup,sync}` (backup + sync: group wheel, written by the user's jobs).

**Felt** (`setup.d/40-felt-tray.sh`, only when `felt-tray` is installed): writes `~/.config/felt-tray/config.toml`
from `/usr/share/clockmost-desktop-config/felt-tray.toml` when missing (clockmost hosts, the vault renewer's cert,
`tray_icon = false` for the bar's Felt chip, `screen_reactions = true`) and Mario's screen-capture blocklist
(`capture_blocklist.toml`, Linux app ids; both only when missing), enables `felt-tray.service`, warns when the session lacks `tray-certs`.

**Per user** (`clockmost-desktop-setup` -> `setup.d/50-clockmost-desktop-config.sh`, safe to repeat): Breeze Dark
(only over the stock light scheme; GTK via kde-gtk-config + breeze-gtk); Xwayland `Scale=1`; KDE Wallet off; `--password-store=gnome-libsecret` for Spotify + Equibop (Spotify also native Wayland); KeePassXC Secret Service on
without per-access prompts, starting minimized into the bar's app tray (only while KeePassXC is closed); one
KeePassXC at login - its own autostart entry goes when the tang unlock entry exists, and Plasma's session restore
skips KeePassXC + Spotify (`ksmserverrc` `excludeApps`; a restored plain KeePassXC beat the tang unlock and left the
vault locked, Spotify hung on it); System Monitor on Ctrl+Shift+Esc (the process list, like Windows' Task Manager); Spectacle = ShareX keys (Ctrl+Print region shot to
annotate + clipboard, Ctrl+Shift+Print region recording, Print) + English OCR.

**Not here (per machine):** the agent's `Server`/`ServerActive`/`Hostname`, Wazuh enrolment, keys, the workspace
scripts (`desktop-backup.sh`, `gdrive-bisync.sh`, `keepass-tang-*.sh`) and their user units.
