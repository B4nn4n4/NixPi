{ ... }:

{
  # Podman backend for OCI containers (required for oci-containers.backend = "podman").
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
  };

  # Persistent storage for Home Assistant container config (/config inside container).
  # A fresh host starts at HA onboarding. To seed it from an existing instance,
  # untar a backup into this directory before first start.
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
        # ACLs are MANDATORY here: the NixOS module always loads mosquitto's
        # acl_file plugin, and a user with an empty `acl` list gets a bare
        # "user <name>" entry with no topics — which means *denied for
        # everything*. The failure is silent: clients authenticate fine and
        # publishes at QoS 0/1 still return success, while the broker logs
        # "Denied PUBLISH" and drops every message on the floor.
        users = {
          # HA needs the whole tree: it drives cmnd/, reads tele/ + stat/,
          # consumes tasmota/discovery/, and publishes homeassistant/status.
          homeassistant = {
            password = "H3dO4KVyDx7XuYmI5J0E";
            acl = [ "readwrite #" ];
          };
          # Tasmota devices publish telemetry/state/discovery and only need to
          # *read* commands addressed to them.
          tasmota = {
            password = "9cXV0azzNExUWrqWBk3i";
            acl = [
              "readwrite tasmota/discovery/#"
              "readwrite tele/#"
              "readwrite stat/#"
              "read cmnd/#"
            ];
          };
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
