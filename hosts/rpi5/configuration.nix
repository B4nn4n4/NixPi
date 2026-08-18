{ pkgs, ... }:

{
  networking.hostName = "rpi5";

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

  # Anytype Sync Server (any-sync-bundle)
  virtualisation.oci-containers = {
    backend = "podman";
    containers.anytype = {
      image = "ghcr.io/grishy/any-sync-bundle:1.5.0-2026-07-17";
      ports = [ "33010:33010" "33020:33020/udp" ];
      volumes = [ "/var/lib/anytype:/data" ];
      environment = {
        ANY_SYNC_BUNDLE_INIT_EXTERNAL_ADDRS = "";
      };
      autoStart = true;
    };
  };

  # Firewall
  networking.firewall = {
    allowedTCPPorts = [ 8123 33010 ];
    allowedUDPPorts = [ 33020 ];
  };
}
