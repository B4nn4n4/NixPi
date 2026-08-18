{ pkgs, ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
    };
  };

  users.users.nixos = {
    isNormalUser = true;
    password = "nixos";
    extraGroups = [ "wheel" ];
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
        git clone https://github.com/B4nn4n4/NixPi.git "$REPO_DIR"
      fi

      echo "Pulling latest changes..."
      git -C "$REPO_DIR" pull --ff-only

      echo "Rebuilding NixOS..."
      sudo nixos-rebuild switch --flake "$REPO_DIR#$FLAKE_ATTR"
    '')
  ];

  system.stateVersion = "26.05";
}
