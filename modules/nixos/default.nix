{ lib, config, ... }:
with lib;
let cfg = config.environment.nix-persist;
in {
  imports = [ ./common.nix ./essential.nix ];
  options.environment.nix-persist = mkOption {
    description = "nix-persist settings";
    default = { };
    type = types.submodule {
      options = {
        enable = mkEnableOption "nix-persist";
        path = mkOption {
          description = "Default path for persistence";
          default = throw "You must set path to persistent storage";
          example = "/persist/nixos";
          type = types.str;
        };
        directories = mkOption {
          type = with types; listOf (either str attrs);
          default = [ ];
          description = "Extra directories to persist";
        };
        files = mkOption {
          type = with types; listOf (either str attrs);
          default = [ ];
          description = "Extra files to persist";
        };
        persistHome = mkOption {
          type = types.bool;
          default = false;
          description = "Persist /home/$USER directory";
        };
        persistTmp = mkOption {
          type = types.bool;
          default = false;
          description = "Persist /tmp (and clean on boot)";
        };
      };
    };
  };

  config = mkIf cfg.enable (let
    mkHomePersist = user: ''
      mkdir -p ${cfg.path}/${user.home}
      chown ${user.name}:${user.group} ${cfg.path}/${user.home}
      chmod ${user.homeMode} ${cfg.path}/${user.home}
    '';
    users =
      mkAfter [ config.users.users ] builtins.filter (user: user.createHome)
      (lib.attrValues config.users.users);
  in {
    # wipe /tmp at boot
    boot.tmp.cleanOnBoot = lib.mkIf cfg.persistTmp true;

    environment.persistence.${cfg.path} = {
      hideMounts = true;
      directories = cfg.directories ++ (lib.optionals cfg.persistTmp [{
        directory = "/tmp";
        user = "root";
        group = "root";
        mode = "1777";
      }]) ++ (lib.optionals cfg.persistHome (map (user: "${user.home}") users));
      files = cfg.files;
    };
    programs.fuse.userAllowOther = true;

    system.activationScripts = lib.optionalAttrs cfg.persistHome {
      persistent-dirs.text = lib.concatLines (map mkHomePersist users);
    };
  });
}
