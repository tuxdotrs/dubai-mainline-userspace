# dubai-mainline-userspace

The NixOS side of [dubai-mainline](https://github.com/tuxdotrs/dubai-mainline)
(Motorola Edge 30, SM7325): [Mobile NixOS](https://github.com/mobile-nixos/mobile-nixos)
with the [Denial](https://github.com/denialwm/denial) Wayland compositor.

    default.nix                Mobile NixOS + this device + configuration.nix
    configuration.nix          the system on the phone (Denial via greetd, Waydroid, user, ssh, ...)
    denial/                    Denial for aarch64: its ARM64 cross-build (meta repo
                               `./build.sh denial`) + upstream packaging files
    devices/motorola-dubai/    device module: boot image, stage-1, USB, firmware,
                               Qualcomm services, sound
    mobile-nixos/              submodule: upstream Mobile NixOS (branch development)
    patches/                   our changes to it, applied by default.nix

The kernel comes from [dubai-mainline-kernel](https://github.com/tuxdotrs/dubai-mainline-kernel),
found through `motorola-dubai.kernelDir` (default: `../kernel`, its place in
the meta repo). Build from the meta repo: `./build.sh system boot`. The Denial
ARM64 binaries come from this repo's releases (`denial-<rev>`), built by the
meta repo's `./build.sh denial`.
Docs: dubai-mainline `docs/`.
