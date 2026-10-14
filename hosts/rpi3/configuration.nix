{ ... }:

{
  networking.hostName = "rpi3";

  # Home Assistant and Mosquitto moved to rpi5 (see modules/home-assistant.nix,
  # imported by hosts/rpi5). Deliberately NOT imported here: two hosts importing
  # it would stand up a second HA instance and a second broker, and the Tasmota
  # devices point at rpi5. This host's old HA state is still on its SD card in
  # /var/lib/hass if anything needs recovering from it.
  #
  # NOTE: this Pi's SD card is failing and it has been stuck in initrd since
  # 2026-10-11, so nothing here has been applied to live hardware.
}
