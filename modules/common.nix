{ pkgs, ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHMegvyvZgDLbOGebJrQVMtY46qwIL3385EmnGdAr/LYAAAABHNzaDo= fabian@AlienSpaceShip"
    ];
  };

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "@wheel" ];
    };
  };

  environment.systemPackages = with pkgs; [
    git
    (pkgs.writeShellScriptBin "nixpi-rebuild" ''
      set -euo pipefail
      REPO_DIR="/etc/nixos/NixPi"
      FLAKE_ATTR="rpi5"

      if [ ! -d "$REPO_DIR" ]; then
        echo "Cloning NixPi repo..."
        sudo git clone https://github.com/B4nn4n4/NixPi.git "$REPO_DIR"
      fi

      echo "Setting repo ownership..."
      sudo chown -R "$USER":"$USER" "$REPO_DIR"

      echo "Pulling latest changes..."
      git -C "$REPO_DIR" pull --ff-only

      echo "Rebuilding NixOS..."
      sudo nixos-rebuild switch --flake "$REPO_DIR#$FLAKE_ATTR"
    '')
  ];

  system.stateVersion = "26.05";
}
