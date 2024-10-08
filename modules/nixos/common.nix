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
    enable = mkOption {
      type = types.bool;
      default = true;
      description =
        "common services and programs files into persistent storage";
    };

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

    libvirtd.enable =
      PersistOption "libvirtd" config.virtualisation.libvirtd.enable;
    openssh.enable = PersistOption "openssh" config.services.openssh.enable;

    tailscale.enable =
      PersistOption "tailscale" config.services.tailscale.enable;

    asusd.enable = PersistOption "asusd" config.services.asusd.enable;

    ly.enable = PersistOption "ly" config.services.displayManager.ly.enable;

    ollama.enable = PersistOption "ollama" config.services.ollama.enable;
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
      }] ++ lib.optionals cfg.libvirtd.enable [{
        directory = "/var/lib/libvirt";
        user = "root";
        group = "root";
        mode = "0755";
      }] ++ lib.optionals cfg.tailscale.enable [{
        directory = "/var/lib/tailscale";
        user = "root";
        group = "root";
        mode = "0700";
      }] ++ lib.optionals cfg.asusd.enable [{
        directory = "/etc/asusd";
        user = "root";
        group = "root";
        mode = "0755";
      }] ++ lib.optionals cfg.ollama.enable [{
        directory = "/var/lib/ollama";
        user = "ollama";
        group = "ollama";
        mode = "0755";
      }];
      files = [ ] ++ lib.optionals cfg.ly.enable [ "/etc/ly/save.ini" ]
        ++ lib.optionals cfg.openssh.enable [
          # keep ssh fingerprints stable
          "/etc/ssh/ssh_host_ed25519_key"
          "/etc/ssh/ssh_host_ed25519_key.pub"
          "/etc/ssh/ssh_host_rsa_key"
          "/etc/ssh/ssh_host_rsa_key.pub"
        ];
    };
  };
}
