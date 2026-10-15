#!/bin/bash
# Felt (felt-tray) on the clockmost desktop (see clockmost-desktop-setup). Skipped when felt-tray isn't installed.
set -eu
command -v felt-tray >/dev/null || { echo "   felt-tray not installed - skipped"; exit 0; }

cfg="${XDG_CONFIG_HOME:-$HOME/.config}/felt-tray/config.toml"
if [[ ! -e $cfg ]]; then
    install -Dm644 /usr/share/clockmost-desktop-config/felt-tray.toml "$cfg"
    echo "   felt-tray: clockmost config written ($cfg)"
fi

systemctl --user daemon-reload
systemctl --user enable felt-tray.service >/dev/null 2>&1 && echo "   felt-tray starts with the session"

# the tray's client cert is readable by group tray-certs (the vault renewer's install adds the user)
if ! id -nG | tr ' ' '\n' | grep -qx tray-certs; then
    echo "   felt-tray: not in group tray-certs in this session - install the vault renewer (clockmost-infra" \
        "projects/openbao/offhost/install-laptop.sh $USER tray), then log in again"
fi
