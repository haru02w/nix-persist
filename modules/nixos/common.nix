{ lib, config, ... }:
with lib;
let
  cfg = config.environment.nix-persist.common;
  inherit (config.environment.nix-persist) path;
  PersistOption = name: default:
    mkOption {
      type = types.bool;
      default = default;
      description = "Enable ${name} persistence";
    };
in {
  options.environment.nix-persist.common = {
    enable = mkEnableOption
      "Common services and programs files into persistent storage";

    networkmanager.enable =
      PersistOption "networkmanager" config.networking.networkmanager.enable;

    bluetooth.enable =
      PersistOption "bluetooth" config.hardware.bluetooth.enable;

    iwd.enable = PersistOption "iwd" config.networking.wireless.iwd.enable;

    dhcpcd.enable = PersistOption "dhcpcd" (builtins.any (x: x.useDHCP != false)
      (builtins.attrValues config.networking.interfaces)
      || config.networking.useDHCP);

    sudo.enable = PersistOption "sudo" config.security.sudo.enable;

    docker.enable = PersistOption "docker" config.virtualisation.docker.enable;

    libvirt.enable =
      PersistOption "libvirt" config.virtualisation.libvirtd.enable;
    openssh.enable = PersistOption "openssh" config.services.openssh.enable;
  };

  config = mkIf cfg.enable {
    environment.persistence.${path} = {
      directories = [ ] ++ lib.optionals cfg.networkmanager.enable [
        {
          directory = "/etc/NetworkManager/system-connections";
          mode = "0700";
        }
        {
          directory = "/var/lib/NetworkManager";
          mode = "0755";
        }
      ] ++ lib.optionals cfg.bluetooth.enable [{
        directory = "/var/lib/bluetooth";
        user = "root";
        group = "root";
        mode = "0755";
      }] ++ lib.optionals cfg.iwd.enable [{
        directory = "/var/lib/iwd";
        user = "root";
        group = "root";
        mode = "0700";
      }] ++ lib.optionals cfg.dhcpcd.enable [{
        directory = "/var/db/dhcpcd";
        user = "root";
        group = "root";
        mode = "0755";
      }] ++ lib.optionals cfg.sudo.enable [{
        directory = "/var/db/sudo/lectured";
        user = "root";
        group = "root";
        mode = "0700";
      }] ++ lib.optionals cfg.docker.enable [{
        directory = "/var/lib/docker";
        user = "root";
        group = "root";
        mode = "0710";
      }] ++ lib.optionals cfg.libvirt.enable [{
        directory = "/var/lib/libvirt";
        user = "root";
        group = "root";
        mode = "0755";
      }];
      files = [ ] ++ lib.optionals cfg.openssh.enable [
        # keep ssh fingerprints stable
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ];
    };
  };
}
