{
  pkgs ? import <nixpkgs> {},
  lib ? pkgs.lib,
  # older version of nixos-container is required for compatibility with older systemd
  nixos-container ? (import (builtins.fetchTarball https://github.com/NixOS/nixpkgs-channels/archive/nixos-19.09.tar.gz) {}).nixos-container
}:
let
  configuration = { config, pkgs, modulesPath, ... }: {
    imports = [
      "${modulesPath}/virtualisation/docker-image.nix"
    ];
    time.timeZone = "America/Halifax";
    system.stateVersion = "19.09";
    boot.enableContainers = true;
    systemd.services."container@" = {
      # the start script fails to touch these if they are broken symlinks
      preStart = ''
        if [ -d $root ]
        then
          rm $root/etc/{os-release,machine-id}
        fi
      '';
    };
    networking.nat = {
      enable = true;
      internalInterfaces = ["ve-+"];
      externalInterface = "eth0";
    };
  };
  nixos = if lib ? nixosSystem
  then lib.nixosSystem {
    modules = [ configuration ];
    system = pkgs.system;
  }
  else import "${pkgs.path}/nixos" {
    inherit configuration;
    system = pkgs.system;
  };
  system = nixos.config.system.build.toplevel;

  install-nixos-container = pkgs.writeShellScript "" ''
    set -euo pipefail
    ln -is ${system}/etc/systemd/system/{nat,container@}.service /etc/systemd/system
    mkdir -p /etc/systemd/system/network.target.wants
    ln -is ${system}/etc/systemd/system/nat.service /etc/systemd/system/network.target.wants
    systemctl daemon-reload
  '';
in
  with pkgs;
  stdenv.mkDerivation {
    name = "container-system";
    unpackPhase = ":";
    installPhase = ''
      mkdir -p $out/bin $out/etc/systemd/system
      ln -s ${nixos-container}/bin/nixos-container $out/bin/nixos-container
      ln -s ${system}/etc/systemd/system/{nat,container@}.service $out/etc/systemd/system/
      ln -s ${install-nixos-container} $out/bin/install-nixos-container
    '';
  }
