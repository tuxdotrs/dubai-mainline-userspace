# Boot menus for the U-Boot in dubai-mainline-bootloader, written by
# switch-to-configuration boot/switch. The ABL boot.img path doesn't use them.
#
# /boot/extlinux/extlinux.conf: NixOS' generic-extlinux-compatible builder
# (Mobile NixOS force-disables the module itself, so it's called directly).
# Each APPEND gets ${abl_bootargs}, which U-Boot sets to ABL's
# /chosen/bootargs (androidboot.*, wifimacaddr, btmacaddr, ...); init= in
# APPEND picks the generation in Mobile NixOS' stage-1.
#
# /boot/extlinux/u-boot-menu.env: the same entries as U-Boot `bootmenu`
# items (volume keys + power; extlinux' own menu wants a typed number), plus
# U-Boot's tools. Imported with `env import -t` by dubai_boot in dubai.env;
# each item sets k/i/a (kernel, initrd, args) and runs dubai_bootgen.
{ config, lib, pkgs, modulesPath, ... }:

let
  builder = import "${modulesPath}/system/boot/loader/generic-extlinux-compatible/extlinux-conf-builder.nix" {
    inherit lib pkgs;
  };
  timeout = if config.boot.loader.timeout == null then "-1" else toString config.boot.loader.timeout;

  # extlinux.conf -> bootmenu env
  toMenu = pkgs.writeText "extlinux-to-bootmenu.awk" ''
    /^LABEL /        { n++; tag[n] = $2; sub(/^nixos-/, "", tag[n]); sub(/-default$/, "", tag[n]) }
    /^  MENU LABEL / { if (match($0, /\(([0-9-]+ [0-9:]+)/)) date[n] = substr($0, RSTART + 1, RLENGTH - 1) }
    /^  LINUX /      { k[n] = $2; sub(/^\.\.\//, "/boot/", k[n]) }
    /^  INITRD /     { i[n] = $2; sub(/^\.\.\//, "/boot/", i[n]) }
    /^  APPEND /     { a[n] = substr($0, index($0, "APPEND ") + 7) }
    END {
      for (e = 1; e <= n; e++) {
        title = tag[e] == "default" ? "NixOS (default)" : "NixOS generation " tag[e] " (" date[e] ")"
        printf "dubai_gen%d=setenv k %s; setenv i %s; setenv a \"%s\"\n", e - 1, k[e], i[e], a[e]
        printf "bootmenu_%d=%s=run dubai_gen%d dubai_bootgen\n", e - 1, title, e - 1
      }
      m = n
      printf "bootmenu_%d=Enable serial console gadget=run serial_gadget\n", m++
      printf "bootmenu_%d=Enable USB mass storage=echo \"Press any key to exit UMS mode\"; ums 0 scsi 0\n", m++
      printf "bootmenu_%d=Drop to shell=setenv bootretry -1\n", m++
      printf "bootmenu_%d=Reset device=reset\n", m++
      printf "bootmenu_%d=Power off=poweroff\n", m++
      # drop the default environment's own items past ours
      for (; m < 32; m++) printf "bootmenu_%d=\n", m
    }
  '';
in
{
  system.build.installBootLoader = pkgs.writeScript "install-extlinux-conf.sh" ''
    #!${pkgs.runtimeShell}
    set -e
    ${builder} -g 10 -t ${timeout} -d /boot -c "$@"
    ${pkgs.gnused}/bin/sed -i 's/^  APPEND .*/& ''${abl_bootargs}/' /boot/extlinux/extlinux.conf
    ${pkgs.gawk}/bin/awk -f ${toMenu} /boot/extlinux/extlinux.conf > /boot/extlinux/u-boot-menu.env.tmp
    mv /boot/extlinux/u-boot-menu.env.tmp /boot/extlinux/u-boot-menu.env
  '';
}
