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
      "google_translate"
      "mqtt"
      "homekit"
    ];
    config = {
      default_config = {};
      mqtt = {
        broker = "127.0.0.1";
        port = 1883;
        username = "homeassistant";
        password = "H3dO4KVyDx7XuYmI5J0E";
      };
      http = {
        server_port = 8123;
        trusted_proxies = [ "127.0.0.1" "::1" ];
      };
    };
  };

  # MQTT broker for Tasmota devices and Home Assistant
  services.mosquitto = {
    enable = true;
    listeners = [
      {
        users = {
          homeassistant = { password = "H3dO4KVyDx7XuYmI5J0E"; };
          tasmota = { password = "9cXV0azzNExUWrqWBk3i"; };
        };
        settings = {
          allow_anonymous = "false";
        };
      }
    ];
  };

  # Firewall
  networking.firewall = {
    allowedTCPPorts = [ 8123 1883 ];
  };
}
