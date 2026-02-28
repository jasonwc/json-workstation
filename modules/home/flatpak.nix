{ ... }:

{
  services.flatpak.packages = [
    "com.spotify.Client"
    "com.visualstudio.code"
    "org.wezfurlong.wezterm"
  ];

  services.flatpak.update.onActivation = true;
  services.flatpak.uninstallUnmanaged = true;
}
