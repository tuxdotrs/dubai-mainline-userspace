# The system that goes on the phone. Device support lives in devices/motorola-dubai.
{ config, lib, pkgs, ... }:

let
  userName = "user";
in
{
  # Plasma Mobile. nixpkgs packages it but has no option for it, so this is
  # Plasma 6 plus the plasma-mobile session and the mobile apps.
  services.desktopManager.plasma6.enable = true;
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
    };
    sessionPackages = [ pkgs.kdePackages.plasma-mobile ];
    defaultSession = "plasma-mobile";
    # SDDM's greeter isn't usable by touch; Plasma Mobile has its own lock
    # screen, where the password is the PIN.
    autoLogin = {
      enable = true;
      user = userName;
    };
  };
  environment.systemPackages = (with pkgs.kdePackages; [
    plasma-mobile
    plasma-dialer
    spacebar # SMS
    plasma-settings
    plasma-phonebook
    plasma-camera
    qmlkonsole
    angelfish
    kclock
    kweather
    kalk
  ]) ++ (with pkgs; [
    maliit-framework
    maliit-keyboard # on-screen keyboard
    hunspellDicts.en_US
  ]);
  # Nothing sets KWin's input method, so the Maliit keyboard never starts.
  environment.etc."xdg/kwinrc".text = ''
    [Wayland]
    InputMethod=/run/current-system/sw/share/applications/com.github.maliit.keyboard.desktop
    VirtualKeyboardEnabled=true
  '';
  programs.feedbackd.enable = true; # haptics
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

  # With ibus (GTK_IM_MODULE=ibus) text input bypasses the Wayland input
  # method and the on-screen keyboard never shows.
  i18n.inputMethod.enable = lib.mkForce false;
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
