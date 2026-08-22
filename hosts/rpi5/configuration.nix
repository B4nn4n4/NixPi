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

  # Create the volume dir for the Anytype container (podman bind-mount source)
  systemd.tmpfiles.rules = [ "d /var/lib/anytype 0755 root root -" ];

  # Anytype Sync Server (any-sync-bundle)
  virtualisation.oci-containers = {
    backend = "podman";
    containers.anytype = {
      image = "ghcr.io/grishy/any-sync-bundle:1.5.0-2026-07-17";
      ports = [ "33010:33010" "33020:33020/udp" ];
      volumes = [ "/var/lib/anytype:/data" ];
      environment = {
        ANY_SYNC_BUNDLE_INIT_EXTERNAL_ADDRS = "10.1.1.12";
      };
      autoStart = true;
    };
  };

  # Pi-hole (DNS-only; DHCP stays on the router)
  services.pihole-ftl = {
    enable = true;
    openFirewallDNS = true;
    openFirewallWebserver = true;
    queryLogDeleter.enable = true;
    lists = [
      {
        url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
        description = "Steven Black unified adlist";
      }
    ];
    settings = {
      dns = {
        upstreams = [
          "1.1.1.2"
          "9.9.9.9"
        ];
        revServers = [ "true,10.1.1.0/24,10.1.1.1" ];
      };
      webserver.api.cli_pw = true;
    };
  };

  services.pihole-web = {
    enable = true;
    ports = [ 80 ];
  };

  # Firewall
  networking.firewall = {
    allowedTCPPorts = [ 8123 33010 ];
    allowedUDPPorts = [ 33020 ];
  };
}
