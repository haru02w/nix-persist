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
        persistTmp = mkOption {
          type = types.bool;
          default = true;
          description = "Persist /tmp (and clean on boot)";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # wipe /tmp at boot
    boot.tmp.cleanOnBoot = lib.mkIf cfg.persistTmp true;

    environment.persistence.${cfg.path} = {
      hideMounts = true;
      directories = cfg.directories ++ lib.optionals cfg.persistTmp [{
        directory = "/tmp";
        user = "root";
        group = "root";
        mode = "1777";
      }];
      files = cfg.files;
    };
  };
}
