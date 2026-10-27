# nix-build -A outputs.default                 (images; see dubai-mainline's build.sh)
# nixos-rebuild switch --file default.nix ...   (updates)
# Builds natively for aarch64 (binfmt on x86_64); the kernel is cross-compiled.
{ device ? ./devices/motorola-dubai, system ? "aarch64-linux", ... }@args:

let
  # Upstream Mobile NixOS (./mobile-nixos) with ./patches applied. Its modules
  # are evaluated, so the patched tree is built first and imported from.
  pkgs = import ./mobile-nixos/pkgs.nix { };
  mobile-nixos = pkgs.applyPatches {
    name = "mobile-nixos";
    src = builtins.path {
      name = "mobile-nixos-src";
      path = ./mobile-nixos;
      filter = path: _: baseNameOf path != ".git";
    };
    patches = [
      # hardware.socs.qualcomm-sm7325
      ./patches/qualcomm-sm7325.patch
      # ABL wants a v2 header with a DTB section: mobile.system.android.bootimg.extraArgs
      ./patches/android-bootimg-extra-args.patch
      # ABL passes console=null and the initrd has no /dev/console: init got EBADF
      ./patches/stage-1-console-stdio.patch
      # A gzip initrd overlapped the DTB
      ./patches/stage-1-zstd.patch
      # qcom-battmgr answers EAGAIN until the ADSP runs; udevadm trigger aborted stage-1
      ./patches/stage-1-udev-trigger-nonfatal.patch
    ];
  };
in
import "${mobile-nixos}/lib/eval-with-configuration.nix" (args // {
  inherit device system;
  configuration = [ ./configuration.nix ];
})
