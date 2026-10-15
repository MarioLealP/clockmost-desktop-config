#!/bin/bash
# clockmost-desktop-config's per-user settings (see clockmost-desktop-setup). Safe to repeat.
set -eu
cfg="${XDG_CONFIG_HOME:-$HOME/.config}"
k() { kwriteconfig6 --file "$1" --group "$2" --key "$3" "$4"; }

# X11 apps at native pixels: Plasma's "legacy apps scale themselves" takes the largest output scale (a 200% tablet)
# and Wine/Steam then saw the screens doubled (FFXIV filled half the screen)
k kwinrc Xwayland Scale 1
qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
echo "   X11 apps unscaled (Xwayland Scale=1)"

# dark mode: Breeze Dark + the dark Plasma style, only while the stock light scheme is on (a scheme picked by hand -
# EndfieldDark one day - stays). No global theme: those can reset panel layouts.
scheme=$(kreadconfig6 --group General --key ColorScheme)
case "$scheme" in
    "" | BreezeLight | BreezeClassic)
        plasma-apply-colorscheme BreezeDark >/dev/null 2>&1 || true
        plasma-apply-desktoptheme breeze-dark >/dev/null 2>&1 || true
        echo "   dark mode: Breeze Dark (KDE apps; GTK + websites follow)" ;;
    *) echo "   colour scheme kept: $scheme" ;;
esac

# KDE Wallet off entirely: KeePassXC is the Secret Service (its Secret Service switch is below)
k kwalletrc Wallet Enabled false
k kwalletrc org.freedesktop.secrets apiEnabled false
echo "   KDE Wallet off"

# Chromium-based apps talk to KDE Wallet directly on KDE - send them to the Secret Service (KeePassXC) instead
flag=--password-store=gnome-libsecret
if [ ! -e "$cfg/spotify-launcher.conf" ]; then
    printf '[spotify]\n# KeePassXC is the Secret Service - Chromium would otherwise go to KDE Wallet. Native Wayland.\nextra_arguments = ["%s", "--enable-features=UseOzonePlatform,WaylandWindowDecorations", "--ozone-platform=wayland"]\n' \
        "$flag" >"$cfg/spotify-launcher.conf"
    echo "   Spotify: $flag, native Wayland"
elif ! grep -q -- "$flag" "$cfg/spotify-launcher.conf"; then
    echo "   Spotify: $cfg/spotify-launcher.conf exists without $flag - add it to extra_arguments by hand"
fi
if ! grep -qs -- "$flag" "$cfg/equibop-flags.conf"; then
    printf '# KeePassXC is the Secret Service - Chromium would otherwise go to KDE Wallet\n%s\n' "$flag" >>"$cfg/equibop-flags.conf"
    echo "   Equibop: $flag"
fi

# KeePassXC = the Secret Service, no per-access prompt (apps only see the group exposed in the database settings),
# starts minimized into the bar's app tray. KeePassXC rewrites its ini on exit, so only while it's closed.
if pgrep -x keepassxc >/dev/null; then
    echo "   KeePassXC running - its settings skipped (close it and re-run)"
else
    k "$cfg/keepassxc/keepassxc.ini" FdoSecrets Enabled true
    k "$cfg/keepassxc/keepassxc.ini" FdoSecrets ConfirmAccessItem false
    k "$cfg/keepassxc/keepassxc.ini" GUI ShowTrayIcon true
    k "$cfg/keepassxc/keepassxc.ini" GUI MinimizeToTray true
    k "$cfg/keepassxc/keepassxc.ini" GUI MinimizeOnStartup true
    echo "   KeePassXC: Secret Service on, no per-access prompt, starts in the tray"
fi

# exactly one KeePassXC at login: the tang unlock entry (workspace scripts/keepass-tang-unlock.sh) starts it unlocked.
# A second, plain one (its own "launch at system startup" entry, or Plasma's session restore) wins the race and
# leaves the vault locked - and Spotify, started in the same second, hangs on the locked Secret Service.
if [ -e "$cfg/autostart/keepass-tang-unlock.desktop" ] && [ -e "$cfg/autostart/org.keepassxc.KeePassXC.desktop" ]; then
    rm -f "$cfg/autostart/org.keepassxc.KeePassXC.desktop"
    echo "   KeePassXC's own autostart removed (the tang unlock entry starts it)"
fi
# Plasma's Wayland session restore applies excludeApps (desktop ids) when it saves the session at logout
excl=$(kreadconfig6 --file ksmserverrc --group General --key excludeApps)
for app in org.keepassxc.KeePassXC.desktop spotify-launcher.desktop; do
    case ",$excl," in *",$app,"*) ;; *) excl="${excl:+$excl,}$app" ;; esac
done
k ksmserverrc General excludeApps "$excl"
echo "   session restore skips KeePassXC + Spotify"

# Spectacle = the ShareX keys: Ctrl+Print region shot (annotate + clipboard), Ctrl+Shift+Print region recording,
# Print opens it; the Plasma defaults (Meta+Shift+S/Print/R) go. Key codes: Ctrl+Print 83886089,
# Ctrl+Shift+Print 117440521, Print 16777225.
sp() {
    busctl --user call org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel setForeignShortcutKeys 'asa(ai)' \
        4 org.kde.spectacle.desktop "$1" Spectacle "$2" 1 1 "$3" 2>/dev/null
}
if sp RectangularRegionScreenShot "Capture Rectangular Region" 83886089 &&
    sp RecordRegion "Record Rectangular Region" 117440521 && sp _launch Spectacle 16777225; then
    echo "   Spectacle: Ctrl+Print / Ctrl+Shift+Print / Print"
else
    echo "   Spectacle keys: kglobalaccel not reachable - re-run inside the Plasma session"
fi
k spectaclerc General launchAction TakeRectangularScreenshot
k spectaclerc General clipboardGroup PostScreenshotCopyImage
k spectaclerc General ocrLanguages eng

# task manager like Windows: Ctrl+Shift+Esc = System Monitor's process list (End / Kill process); Meta+Esc (its own
# default) = the overview. kglobalaccel only knows apps from its last sycoca scan, so rebuild that first.
kbuildsycoca6 >/dev/null 2>&1 || true
if busctl --user call org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel setForeignShortcutKeys 'asa(ai)' \
    4 org.kde.plasma-systemmonitor.desktop processes "System Monitor" "Open Processes Page" 1 1 117440512 2>/dev/null; then
    echo "   System Monitor: Ctrl+Shift+Esc (processes)"
else
    echo "   System Monitor key: kglobalaccel not reachable - re-run inside the Plasma session"
fi
