# dubai-mainline-userspace

The NixOS side of [dubai-mainline](https://github.com/tuxdotrs/dubai-mainline)
(Motorola Edge 30, SM7325): [Mobile NixOS](https://github.com/mobile-nixos/mobile-nixos)
with Plasma Mobile.

    default.nix                Mobile NixOS + this device + configuration.nix
    configuration.nix          the system on the phone (user, Plasma Mobile, ssh, ...)
    devices/motorola-dubai/    device module: boot image, stage-1, USB, firmware,
                               Qualcomm services, sound
    mobile-nixos/              submodule: upstream Mobile NixOS (branch development)
    patches/                   our changes to it, applied by default.nix

The kernel comes from [dubai-mainline-kernel](https://github.com/tuxdotrs/dubai-mainline-kernel),
found through `motorola-dubai.kernelDir` (default: `../kernel`, its place in
the meta repo). Build from the meta repo: `./build.sh system boot`.
Docs: dubai-mainline `docs/`.
