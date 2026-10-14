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
- `tmpfiles.d`: `/var/lib/clockmost-{health,backup,sync}` (backup + sync: group wheel, written by the user's jobs).

**Per user** (`clockmost-desktop-setup` -> `setup.d/50-clockmost-desktop-config.sh`, safe to repeat): Xwayland
`Scale=1`; KDE Wallet off; `--password-store=gnome-libsecret` for Spotify + Equibop; KeePassXC Secret Service on
without per-access prompts (only while KeePassXC is closed); Spectacle = ShareX keys (Ctrl+Print region shot to
annotate + clipboard, Ctrl+Shift+Print region recording, Print) + English OCR.

**Not here (per machine):** the agent's `Server`/`ServerActive`/`Hostname`, Wazuh enrolment, keys, the workspace
scripts (`desktop-backup.sh`, `gdrive-bisync.sh`, `keepass-tang-*.sh`) and their user units.
