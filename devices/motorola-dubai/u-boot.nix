# /boot/extlinux/extlinux.conf for the U-Boot in dubai-mainline-bootloader:
# a menu entry per generation, written by switch-to-configuration boot/switch.
# The ABL boot.img path doesn't use it; it only matters once U-Boot boots.
#
# NixOS' generic-extlinux-compatible builder does the work (Mobile NixOS
# force-disables the module itself, so it's called directly). U-Boot sets
# ${abl_bootargs} to ABL's /chosen/bootargs (androidboot.*, wifimacaddr,
# btmacaddr, ...) and expands it in APPEND, after init=, which Mobile NixOS'
# stage-1 uses to pick the generation.
{ config, lib, pkgs, modulesPath, ... }:

let
  builder = import "${modulesPath}/system/boot/loader/generic-extlinux-compatible/extlinux-conf-builder.nix" {
    inherit lib pkgs;
  };
  timeout = if config.boot.loader.timeout == null then "-1" else toString config.boot.loader.timeout;
in
{
  system.build.installBootLoader = pkgs.writeScript "install-extlinux-conf.sh" ''
    #!${pkgs.runtimeShell}
    set -e
    ${builder} -g 10 -t ${timeout} -d /boot -c "$@"
    ${pkgs.gnused}/bin/sed -i 's/^  APPEND .*/& ''${abl_bootargs}/' /boot/extlinux/extlinux.conf
  '';
}
