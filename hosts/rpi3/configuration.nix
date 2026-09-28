{ pkgs, ... }:

{
  networking.hostName = "rpi3";

  # Podman backend for OCI containers (required for oci-containers.backend = "podman").
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
  };

  # Persistent storage for Home Assistant container config (/config inside container).
  # Migration from native module: sudo cp -a /var/lib/hass/. /var/lib/home-assistant/
  # then sudo chown -R root:root /var/lib/home-assistant (or 1000 if rootless).
  # Old state stays in /var/lib/hass as rollback backup — delete manually once verified.
  systemd.tmpfiles.rules = [ "d /var/lib/home-assistant 0755 root root -" ];

  # Home Assistant Container (upstream image, replaces services.home-assistant /
  # HA Core which is unsupported since 2025.12). No Supervisor / Add-on Store in
  # this mode by design — Mosquitto below stays a native NixOS service, other
  # tools (Zigbee2MQTT, ESPHome, Node-RED) would be added as sibling containers.
  # HACS, Tasmota (MQTT), Samsung, EcoFlow integrations all work without Supervisor.
  virtualisation.oci-containers = {
    backend = "podman";
    containers.homeassistant = {
      # Pin to a known release; bump deliberately then `nixpi-rebuild`.
      # NOTE: the image is only re-pulled when this string changes (not on every rebuild).
      image = "ghcr.io/home-assistant/home-assistant:2026.9.1";
      volumes = [ "/var/lib/home-assistant:/config" ];
      environment = {
        TZ = "Europe/Berlin";
      };
      extraOptions = [
        # Host network required for HomeKit/mDNS/SSDP/DLNA discovery.
        # With host networking, `ports` is ignored — HA listens on 8123 directly.
        "--network=host"
        # Uncomment to pass a Zigbee/Z-Wave stick through when needed:
        # "--device=/dev/ttyACM0:/dev/ttyACM0"
      ];
      autoStart = true;
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
    allowedTCPPorts = [ 8123 1883 21063 ];
    # HomeKit bridge needs mDNS discovery on 5353/udp.
    allowedUDPPorts = [ 5353 ];
  };
}
