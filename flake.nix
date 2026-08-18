{
  description = "Raspberry Pi NixOS configurations";

  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi/main";
    };
  };

  outputs = { self, nixpkgs, nixos-raspberrypi }:
  let
    mkPi = { modules }: nixos-raspberrypi.lib.nixosSystem {
      modules = [
        nixos-raspberrypi.nixosModules.sd-image
        ({ lib, ... }:
          {
            boot.supportedFilesystems.zfs = lib.mkForce false;
          })
      ] ++ modules;
    };
  in
  {
    nixosConfigurations = {
      rpi3 = mkPi {
        modules = [
          nixos-raspberrypi.nixosModules.raspberry-pi-3.base
          ./modules/common.nix
          ./hosts/rpi3/configuration.nix
        ];
      };

      rpi5 = mkPi {
        modules = [
          nixos-raspberrypi.nixosModules.raspberry-pi-5.base
          ./modules/common.nix
          ./hosts/rpi5/configuration.nix
        ];
      };
    };

    packages.aarch64-linux = {
      rpi3-image = self.nixosConfigurations.rpi3.config.system.build.sdImage;
      rpi5-image = self.nixosConfigurations.rpi5.config.system.build.sdImage;
    };
  };
}
