#!/bin/bash
# zabbix-desktop-check.sh <check>: values for a clockmost desktop's Zabbix agent UserParameters
# (/etc/zabbix/zabbix_agent2.d/clockmost-desktop.conf; Zabbix side: clockmost-infra ops/zabbix/zbx23).
# SMART + btrfs need root: `collect` runs as root from clockmost-desktop-health.timer and writes
# /var/lib/clockmost-health/desktop.status; the agent (user zabbix, no sudo - Arch creates it expired) only reads it.
# -1 = could not read (or the collected value is older than 2 h) - never a silent 0.
set -u
backup=/var/lib/clockmost-backup/desktop-backup.status # desktop-backup.sh: <epoch> <ok|partial|failed> <rc>
gdrive=/var/lib/clockmost-sync/gdrive.status           # gdrive-bisync.sh: <epoch> <ok|failed> <rc> <last ok epoch>
health=/var/lib/clockmost-health/desktop.status

collected() { # collected <key>: value from the health file, -1 if missing or stale
    [ -r "$health" ] || { echo -1; return; }
    awk -F= -v k="$1" -v now="$(date +%s)" '$1 == "at" {at = $2} $1 == k {v = $2}
        END {print (v == "" || now - at > 7200) ? -1 : v}' "$health"
}

case "${1:-}" in
    collect)
        # internal disks only (SATA/NVMe/SAS): USB sticks and zram never count
        smart=0
        while read -r dev tran; do
            case "$tran" in sata | nvme | sas) ;; *) continue ;; esac
            smartctl -H "$dev" 2>/dev/null | grep -q -E "PASSED|: OK" || smart=$((smart + 1))
        done < <(lsblk -d -n -o PATH,TRAN 2>/dev/null)
        # every mounted btrfs filesystem once (device stats are per filesystem, not per mount)
        btrfs=0
        while read -r _ target; do
            out=$(btrfs device stats "$target" 2>/dev/null) || { btrfs=-1; break; }
            btrfs=$((btrfs + $(awk '{s += $2} END {print s + 0}' <<<"$out")))
        done < <(findmnt -l -t btrfs -n -o UUID,TARGET 2>/dev/null | sort -u -k1,1)
        printf 'at=%s\nsmart_unhealthy=%s\nbtrfs_errors=%s\n' "$(date +%s)" "$smart" "$btrfs" >"$health.tmp"
        mv "$health.tmp" "$health" ;;
    backup-failed) [ -r "$backup" ] && awk '{print ($2 == "failed") ? 1 : 0}' "$backup" || echo -1 ;;
    backup-at) [ -r "$backup" ] && awk '{print $1}' "$backup" || echo 0 ;;
    gdrive-failed) [ -r "$gdrive" ] && awk '{print ($2 == "failed") ? 1 : 0}' "$gdrive" || echo -1 ;;
    gdrive-last-ok) [ -r "$gdrive" ] && awk '{print $4}' "$gdrive" || echo 0 ;;
    units-failed) systemctl list-units --state=failed --no-legend --plain | wc -l ;;
    updates)
        out=$(checkupdates 2>/dev/null)
        case $? in 0) wc -l <<<"$out" ;; 2) echo 0 ;; *) echo -1 ;; esac ;;
    btrfs-errors) collected btrfs_errors ;;
    smart-unhealthy) collected smart_unhealthy ;;
    *) echo "usage: $0 collect|backup-failed|backup-at|gdrive-failed|gdrive-last-ok|units-failed|updates|btrfs-errors|smart-unhealthy" >&2; exit 1 ;;
esac
