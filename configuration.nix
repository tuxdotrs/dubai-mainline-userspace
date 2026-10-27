# The system that goes on the phone. Device support lives in devices/motorola-dubai.
{ config, lib, pkgs, ... }:

let
  userName = "user";
  denial = import ./denial/source.nix;
in
{
  # The Denial compositor, with its own NixOS module (session, portals,
  # Xwayland, polkit) and our ARM64 package.
  imports = [ "${denial.src}/nix/module.nix" ];
  programs.denial = {
    enable = true;
    # ARM64 build published as a release (denial/source.nix); to test a local
    # `./build.sh denial` instead: payload = ../build/denial/<file>.tar.gz
    package = pkgs.callPackage ./denial { payload = pkgs.fetchurl denial.payload; };
    ddc.enable = false;
  };
  # Read by denial-session. card0 (simpledrm) is gone after the msm handoff.
  environment.etc."denial/session.conf".text = ''
    DENIAL_DRM_DEVICE=/dev/dri/by-path/platform-ae01000.display-controller-card
    DENIAL_RENDER_DEVICE=/dev/dri/by-path/platform-ae01000.display-controller-render
    DENIAL_SHELL_PROFILE=mobile
  '';
  # Autologin into Denial on VT1; tuigreet if the session exits.
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        user = userName;
        command = "${config.programs.denial.package}/bin/denial-session";
      };
      default_session.command =
        "${pkgs.tuigreet}/bin/tuigreet --time --cmd ${config.programs.denial.package}/bin/denial-session";
    };
  };
  environment.systemPackages = with pkgs; [
    kitty
  ];
  programs.feedbackd.enable = true; # haptics
  # Android apps in an LXC container (`waydroid init` once, as root)
  virtualisation.waydroid.enable = true;
  # Show the boot: kernel and systemd messages scroll on the display (tty1)
  # instead of a splash. U-Boot's menu picks generations, so stage-1's GUI
  # (splash + generation picker) isn't needed either.
  mobile.beautification = {
    silentBoot = false;
    splash = false;
  };
  mobile.boot.stage-1.gui.enable = false;
  boot.consoleLogLevel = 7;

  users.users.${userName} = {
    isNormalUser = true;
    # The lock screen PIN; change it with `passwd`
    initialPassword = "1234";
    extraGroups = [
      "dialout"
      "feedbackd"
      "networkmanager"
      "video"
      "wheel"
    ];
  };

  networking.hostName = "dubai";
  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  services.openssh.enable = true;

  zramSwap.enable = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # deploy from the PC with nixos-rebuild --target-host
    trusted-users = [ userName ];
  };

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "firmware-motorola-dubai" ];

  system.stateVersion = "26.11";
}
