# Maintainer: Benylin <lealmariop@gmail.com>
#
# Builds from $startdir (the pkgs/ CI checks out the tagged commit and runs makepkg in place). Scripts + config only.

pkgname=clockmost-desktop-config
pkgver=0.1.1
pkgrel=1
pkgdesc="clockmost desktop glue: Zabbix desktop checks + health timer, the apps the desktop needs, and per-user settings (Xwayland scale, KDE Wallet off, KeePassXC Secret Service + one instance at login, Spectacle keys)"
arch=('any')
url="https://git.clockmost.com/pkgs/${pkgname}"
license=('MIT')
depends=(
  'zabbix-agent2' 'smartmontools' 'pacman-contrib' 'btrfs-progs' 'util-linux'  # the Zabbix desktop checks
  'keepassxc' 'qt5-wayland'          # KeePassXC is Qt 5: no Wayland plugin without qt5-wayland
  'rclone' 'restic'                  # the Drive sync + the backup (their scripts live in the workspace)
  'ffmpeg4.4'                        # Spotify decodes local files with libavcodec <= 61
  'fuse2'                            # AppImages (Teamcraft)
  'tesseract-data-eng'               # Spectacle's OCR in English
  'spectacle' 'kconfig'              # kwriteconfig6 for the setup step
  'kde-gtk-config' 'breeze-gtk'      # dark mode reaches GTK apps (KDE syncs the scheme into gtk-3.0/4.0)
)
backup=('etc/zabbix/zabbix_agent2.d/clockmost-desktop.conf')
install="${pkgname}.install"
options=('!debug')

package() {
  cd "$startdir"
  install -Dm755 zabbix/zabbix-desktop-check.sh "$pkgdir/usr/lib/clockmost-desktop-config/zabbix-desktop-check.sh"
  install -Dm644 zabbix/clockmost-desktop.conf "$pkgdir/etc/zabbix/zabbix_agent2.d/clockmost-desktop.conf"
  install -Dm644 -t "$pkgdir/usr/lib/systemd/system" systemd/clockmost-desktop-health.service systemd/clockmost-desktop-health.timer
  install -Dm644 systemd/clockmost-desktop-config.tmpfiles "$pkgdir/usr/lib/tmpfiles.d/clockmost-desktop-config.conf"
  install -Dm644 setup.d/50-clockmost-desktop-config.sh "$pkgdir/usr/share/clockmost-desktop/setup.d/50-clockmost-desktop-config.sh"
  install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
