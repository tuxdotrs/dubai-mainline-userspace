# Denial (https://github.com/denialwm/denial) for aarch64. Its own Nix package
# is x86_64-only (pinned x86-64 Flutter engine), so the binaries come from its
# ARM64 cross-build (cross-build/, run by `./build.sh denial` in the meta repo)
# and the rest from the same revision's source, laid out like its
# nix/package.nix. Not included: the plugin manager.
{ lib
, stdenv
, autoPatchelfHook
, makeWrapper
, payload
, coreutils
, ddcutil
, fontconfig
, freetype
, glib
, gnused
, libdrm
, libgbm
, libglvnd
, libinput
, libpulseaudio
, libxkbcommon
, pam
, polkit
, seatd
, systemd
, util-linux
, wayland
, xwayland
}:

let
  denial = import ./source.nix;
  src = denial.src;
  # The compositor dlopens these (as in Denial's nix/package.nix)
  runtimeLibraries = [ libglvnd pam libpulseaudio ddcutil ];
in
stdenv.mkDerivation {
  pname = "denial";
  version = "0-unstable-${builtins.substring 0 12 denial.rev}";
  src = payload;

  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];
  buildInputs = [
    stdenv.cc.cc.lib
    ddcutil
    fontconfig
    freetype
    glib
    libdrm
    libgbm
    libglvnd
    libinput
    libpulseaudio
    libxkbcommon
    pam
    polkit
    seatd
    systemd
    wayland
  ];

  installPhase = ''
    runHook preInstall

    sha256sum -c SHA256SUMS
    install -Dm755 -t $out/bin bin/deniald bin/denialctl bin/denial-portal
    install -d $out/lib/denial/flutter
    cp -R bundle/. $out/lib/denial/flutter/

    install -Dm755 ${src}/packaging/arch/denial-session $out/bin/denial-session
    patchShebangs $out/bin/denial-session

    # Settings/Welcome and the Polkit dialog: the denial-app runner plus each
    # app's AOT bundle; the engine and ICU data are the shell's (same build)
    for app in settings polkit; do
      name=denial-$app; [ $app = polkit ] && name=denial-polkit-dialog
      install -d $out/lib/denial/$app
      cp -R apps/$name/. $out/lib/denial/$app/
      ln -s ../../flutter/lib/libflutter_engine.so $out/lib/denial/$app/lib/libflutter_engine.so
      ln -s ../../flutter/data/icudtl.dat $out/lib/denial/$app/data/icudtl.dat
    done
    ln -s ../lib/denial/settings/denial-settings $out/bin/denial-settings
    mv $out/lib/denial/polkit/denial-polkit-dialog $out/lib/denial/polkit/denial-app
    install -Dm755 bin/denial-polkit-agent $out/libexec/denial-polkit-agent
    makeWrapper $out/libexec/denial-polkit-agent $out/bin/denial-polkit-agent \
      --add-flags "--runner $out/lib/denial/polkit/denial-app --bundle $out/lib/denial/polkit --engine $out/lib/denial/polkit/lib/libflutter_engine.so"
    install -Dm644 ${src}/packaging/denial-polkit-agent.service \
      $out/lib/systemd/user/denial-polkit-agent.service
    substituteInPlace $out/lib/systemd/user/denial-polkit-agent.service \
      --replace-fail '/usr/bin/denial-polkit-agent' "$out/bin/denial-polkit-agent"
    install -Dm644 ${src}/packaging/arch/dev.denial.Settings.desktop \
      $out/share/applications/dev.denial.Settings.desktop
    install -Dm644 ${src}/packaging/dev.denial.Welcome.desktop \
      $out/share/applications/dev.denial.Welcome.desktop
    substituteInPlace $out/share/applications/dev.denial.{Settings,Welcome}.desktop \
      --replace-fail '/usr/bin/denial-settings' "$out/bin/denial-settings"

    install -Dm644 ${src}/packaging/denial-session.target \
      $out/lib/systemd/user/denial-session.target
    install -Dm644 ${src}/packaging/arch/denial-portal.service \
      $out/lib/systemd/user/denial-portal.service
    substituteInPlace $out/lib/systemd/user/denial-portal.service \
      --replace-fail 'ExecStart=/usr/bin/denial-portal' "ExecStart=$out/bin/denial-portal"

    install -Dm755 ${src}/packaging/denial-suspend-mode \
      $out/lib/systemd/system-sleep/denial-suspend-mode
    substituteInPlace $out/lib/systemd/system-sleep/denial-suspend-mode \
      --replace-fail '#!/bin/sh' '#!${stdenv.shell}' \
      --replace-fail "sed 's/\\[//g; s/\\]//g'" "${gnused}/bin/sed 's/\\[//g; s/\\]//g'" \
      --replace-fail 'command -v loginctl' 'test -x ${systemd}/bin/loginctl' \
      --replace-fail 'loginctl list-sessions' '${systemd}/bin/loginctl list-sessions' \
      --replace-fail 'loginctl show-session' '${systemd}/bin/loginctl show-session' \
      --replace-fail 'loginctl show-user' '${systemd}/bin/loginctl show-user' \
      --replace-fail 'logger -t denial-suspend-mode' '${util-linux}/bin/logger -t denial-suspend-mode'

    install -Dm644 ${src}/packaging/arch/denial.desktop \
      $out/share/wayland-sessions/denial.desktop
    substituteInPlace $out/share/wayland-sessions/denial.desktop \
      --replace-fail '/usr/bin/denial-session' "$out/bin/denial-session"

    install -Dm644 ${src}/packaging/arch/denial-portals.conf \
      $out/share/xdg-desktop-portal/denial-portals.conf
    install -Dm644 ${src}/packaging/arch/denial.portal \
      $out/share/xdg-desktop-portal/portals/denial.portal
    install -Dm644 ${src}/packaging/arch/org.freedesktop.impl.portal.desktop.denial.service \
      $out/share/dbus-1/services/org.freedesktop.impl.portal.desktop.denial.service
    substituteInPlace $out/share/dbus-1/services/org.freedesktop.impl.portal.desktop.denial.service \
      --replace-fail '/usr/bin/denial-portal' "$out/bin/denial-portal"
    install -Dm644 ${src}/packaging/arch/xdg-desktop-portal-wlr-Denial \
      $out/etc/xdg/xdg-desktop-portal-wlr/Denial
    install -Dm644 ${src}/packaging/arch/session.conf $out/etc/denial/session.conf
    install -Dm644 ${src}/packaging/arch/outputs.conf $out/etc/denial/outputs.conf

    for manual in denialctl deniald denial-session denial-portal; do
      install -Dm644 ${src}/docs/man/$manual.1 $out/share/man/man1/$manual.1
    done
    install -Dm644 ${src}/LICENSE $out/share/licenses/denial/LICENSE

    wrapProgram $out/bin/denial-session \
      --prefix PATH : ${lib.makeBinPath [ coreutils systemd xwayland ]}

    runHook postInstall
  '';

  # autoPatchelf rewrites the runpath, so a postFixup --add-rpath (as in
  # Denial's package) would be lost; this is its way to keep them.
  runtimeDependencies = runtimeLibraries;

  passthru.providedSessions = [ "denial" ];

  meta = {
    description = "Flutter-native Wayland compositor and desktop shell (ARM64 cross-build)";
    homepage = "https://github.com/denialwm/denial";
    license = with lib.licenses; [ gpl3Plus gpl3Only cc-by-sa-40 ofl ];
    mainProgram = "denial-session";
    platforms = [ "aarch64-linux" ];
  };
}
