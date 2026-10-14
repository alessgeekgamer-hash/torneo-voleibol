#!/bin/bash
set -e
APP=torneo_voleibol
VER=${VERSION:-1.0.0}
PKG="${APP}_${VER}_amd64"

rm -rf deb_pkg "$PKG.deb"
mkdir -p deb_pkg/DEBIAN
mkdir -p deb_pkg/opt/$APP
mkdir -p deb_pkg/usr/share/applications
mkdir -p deb_pkg/usr/bin

# Bundle de Flutter
cp -r build/linux/x64/release/bundle/* deb_pkg/opt/$APP/

# Control
cat > deb_pkg/DEBIAN/control <<EOF
Package: $APP
Version: $VER
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Torneo Voleibol <soporte@voleibol.local>
Description: Control de torneo de voleibol (2de3/3de5, round robin y eliminacion directa).
 App Flutter multiplataforma para rol de juegos, jornada, captura en vivo y estadisticas.
EOF

# Lanzador
cat > deb_pkg/usr/share/applications/$APP.desktop <<EOF
[Desktop Entry]
Name=Torneo Voleibol
Comment=Control de torneo de voleibol
Exec=/opt/$APP/$APP
Icon=$APP
Terminal=false
Type=Application
Categories=Sport;Utility;
EOF

# Symlink en /usr/bin
ln -sf /opt/$APP/$APP deb_pkg/usr/bin/$APP

# Permisos
chmod -R 755 deb_pkg/opt/$APP
chmod 755 deb_pkg/DEBIAN || true

dpkg-deb --build deb_pkg "$PKG.deb"
echo "DEB generado: $PKG.deb"
ls -lh "$PKG.deb"
