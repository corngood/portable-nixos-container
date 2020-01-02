let
  configuration = { config, pkgs, ... }: {
    imports = [
      <nixpkgs/nixos/modules/virtualisation/docker-image.nix>
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
  nixos = import <nixpkgs/nixos> {
    inherit configuration;
    system = builtins.currentSystem;
  };
  system = nixos.config.system.build.toplevel;
  # older version of nixos-container is required for compatibility with older systemd
  nixos-container =
    (import (builtins.fetchTarball https://github.com/NixOS/nixpkgs-channels/archive/nixos-19.09.tar.gz) {})
    .nixos-container;
in
  { pkgs ? import <nixpkgs> {} }: with pkgs;
  stdenv.mkDerivation {
    name = "container-system";
    unpackPhase = ":";
    installPhase = ''
      mkdir -p $out/bin $out/etc/systemd/system
      ln -s ${nixos-container}/bin/nixos-container $out/bin/nixos-container
      ln -s ${system}/etc/systemd/system/{nat,container@}.service $out/etc/systemd/system/
    '';
  }
