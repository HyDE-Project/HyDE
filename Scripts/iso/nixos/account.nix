{ ... }:
{
  services.displayManager.autoLogin = {
    enable = true;
    user = "root";
  };
  services.displayManager.defaultSession = "hyde-root";
}
