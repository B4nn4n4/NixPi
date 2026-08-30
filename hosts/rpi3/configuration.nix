{ pkgs, ... }:

{
  networking.hostName = "rpi3";

  # Home Assistant
  services.home-assistant = {
    enable = true;
    extraComponents = [
      "analytics"
      "met"
      "radio_browser"
      "isal"
    ];
    config = {
      default_config = {};
      http = {
        server_port = 8123;
        trusted_proxies = [ "127.0.0.1" "::1" ];
      };
    };
  };

  # Firewall
  networking.firewall = {
    allowedTCPPorts = [ 8123 ];
  };
}
