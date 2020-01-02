# Using a non-NixOS distro as a nixos-container host #

1. Install Nix in multi-user mode (https://nixos.org/nix/manual/#sect-multi-user-installation)

2. Install required packages for `systemd-nspawn`

  e.g. on debian: `apt install systemd-container`

3. As root install container-system

  `nix-env -iE 'f: import "${builtins.fetchGit http://github.com/corngood/portable-nixos-container.git}/container-system.nix"'`

4. Symlink systemd units into host system

  ```
  ln -s ~/.nix-profile/etc/systemd/system/{nat,container@}.service /etc/systemd/system
  systemctl daemon-reload
  ```

5. Start and enable nat service (required for containers to have network access)

  ```
  systemctl start nat
  mkdir -p /etc/systemd/system/network.target.wants
  ln -s ~/.nix-profile/etc/systemd/system/nat.service /etc/systemd/system/network.target.wants
  ```

6. Create containers using `nixos-container` or by deploying with `nixops`

7. Permanently enable a container

  `ln -s /etc/systemd/system/container@.service /etc/systemd/system/multi-user.target.wants/container@[container-name].service`

8. Expose ports

  Edit `/etc/containers/[container-name].conf` and add to `HOST_PORT`.  Each word will correspond to the value of a `systemd-nspawn` `--port` argument.

  You must restart the container for configuration changes to have an effect `systemctl restart container@[container-name]`.

  **WARNING** these ports may not be forwarded from the loopback interface.

9. Configure `systemd-nspawn`

  Edit `/etc/containers/[container-name].conf` and add `EXTRA_NSPAWN_FLAGS`.  This variable will be appended to the nspawn arguments, and can contain anything from `man systemd-nspawn`.

  e.g. to create a bind mount: `--bind=/mnt/container/var:/var`

  `systemd-nspawn` may also be configured using `/etc/systemd/nspawn/[container-name].nspawn` according to the manual.
