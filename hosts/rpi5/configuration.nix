{ pkgs, ... }:

{
  networking.hostName = "rpi5";

  # Raspberry Pis have no battery-backed RTC (boots at 1970), so Anytype
  # x509 certs fail ("not yet valid") until NTP syncs. Force explicit NTP
  # servers and delay anytype until time-sync.target is reached.
  services.timesyncd = {
    enable = true;
    servers = [
      "time.google.com"
      "time.cloudflare.com"
      "pool.ntp.org"
    ];
  };
  systemd.services.systemd-timesyncd = {
    after = [ "network-online.target" "pihole-ftl.service" ];
    wants = [ "network-online.target" ];
  };
  systemd.services.podman-anytype = {
    after = [ "time-sync.target" "systemd-timesyncd.service" ];
    wants = [ "time-sync.target" ];
  };

  # Create the volume dir for the Anytype container (podman bind-mount source)
  systemd.tmpfiles.rules = [ "d /var/lib/anytype 0755 root root -" ];

  # Anytype Sync Server (any-sync-bundle)
  # NOTE: ANY_SYNC_BUNDLE_INIT_* is only applied on first run and baked into
  # /var/lib/anytype/bundle-config.yml (externalAddr). To change the address:
  # sudo systemctl stop podman-anytype && sudoedit
  # /var/lib/anytype/bundle-config.yml, then start + re-import regenerated
  # client-config.yml on all devices (new dedicated self-hosted identity).
  virtualisation.oci-containers = {
    backend = "podman";
    containers.anytype = {
      image = "ghcr.io/grishy/any-sync-bundle:1.6.0-2026-08-18";
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
    allowedTCPPorts = [ 33010 ];
    allowedUDPPorts = [ 33020 ];
  };
}
