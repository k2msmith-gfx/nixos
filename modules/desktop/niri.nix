{ pkgs, inputs, ... }:

{
  programs.niri.enable = true;

  environment.systemPackages = with pkgs; [
    waybar
    fuzzel
    mako
    swaybg
    swaylock
    swayidle
    wl-clipboard
    pavucontrol
    networkmanagerapplet
    noctalia-shell
    xwayland-satellite
    adwaita-icon-theme
  ];

  systemd.user.services.swayidle = {
    description = "Idle manager for Wayland";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.swayidle}/bin/swayidle -w before-sleep '${pkgs.swaylock}/bin/swaylock -f' lock '${pkgs.swaylock}/bin/swaylock -f'";
      Restart = "on-failure";
    };
  };

  services.dbus.enable = true;
  security.polkit.enable = true;
  security.pam.services.swaylock = {};

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [
    pkgs.xdg-desktop-portal-gtk
    pkgs.xdg-desktop-portal-gnome
  ];
  xdg.portal.config.common = {
    default = [ "gtk" ];
    "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
    "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
    "org.freedesktop.impl.portal.RemoteDesktop" = [ "gnome" ];
  };
}
